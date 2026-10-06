const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

exports.sendUpiLink = onCall(async (request) => {
  const senderUid = request.auth?.uid;
  if (!senderUid) {
    throw new HttpsError("unauthenticated", "Sign in before sending a UPI link.");
  }

  const billTitle =
    typeof request.data?.billTitle === "string"
      ? request.data.billTitle.trim().slice(0, 120)
      : "";
  const rows = request.data?.rows;
  if (!billTitle.trim() || !Array.isArray(rows) || rows.length > 100) {
    throw new HttpsError("invalid-argument", "Bill details are invalid.");
  }

  const profileDoc = await db.collection("users").doc(senderUid).get();
  const profile = profileDoc.data() || {};
  const upiId =
    typeof profile.upiId === "string" ? profile.upiId.trim() : "";
  if (!upiId) return { noUpiId: true, sent: 0, skipped: 0 };

  const targets = new Map();
  let skipped = 0;
  for (const row of rows) {
    const uid = typeof row?.linkedUid === "string" ? row.linkedUid : "";
    const amount = Number(row?.amount);
    if (!uid || uid === senderUid || !Number.isFinite(amount) || amount <= 0) {
      skipped++;
      continue;
    }
    if (!targets.has(uid)) {
      targets.set(uid, {
        amount,
      });
    }
  }

  if (!targets.size) return { noUpiId: false, sent: 0, skipped };

  const targetUids = [...targets.keys()];
  const linkedUids = new Set();
  const friendDocs = await db
    .collection("friends")
    .where("ownerId", "==", senderUid)
    .get();
  for (const friendDoc of friendDocs.docs) {
    const uid = friendDoc.data().linkedUid;
    if (targets.has(uid)) linkedUids.add(uid);
  }

  const authorizedUids = targetUids.filter((uid) => linkedUids.has(uid));
  skipped += targetUids.length - authorizedUids.length;
  if (!authorizedUids.length) {
    return { noUpiId: false, sent: 0, skipped };
  }

  const receiverName =
    typeof profile.fullName === "string" && profile.fullName.trim()
      ? profile.fullName.trim().slice(0, 80)
      : "SplitPay user";
  const userDocs = await Promise.all(
    authorizedUids.map((uid) => db.collection("users").doc(uid).get()),
  );
  const messages = [];
  for (let index = 0; index < authorizedUids.length; index++) {
    const token = userDocs[index].data()?.fcmToken;
    if (typeof token !== "string" || !token) {
      skipped++;
      continue;
    }
    const uid = authorizedUids[index];
    const target = targets.get(uid);
    const params = new URLSearchParams({
      pa: upiId,
      pn: receiverName,
      am: target.amount.toFixed(2),
      cu: "INR",
      tn: billTitle,
    });
    messages.push({
      token,
      notification: {
        title: "UPI payment link",
        body: `Pay ₹${target.amount.toFixed(2)} for "${billTitle}" to ${receiverName} (${upiId}).`,
      },
      data: {
        type: "upi_payment_link",
        upiUri: `upi://pay?${params.toString()}`,
        billTitle,
        amount: target.amount.toFixed(2),
        upiId,
        receiverName,
      },
    });
  }

  let sent = 0;
  for (let index = 0; index < messages.length; index += 500) {
    const response = await admin.messaging().sendEach(messages.slice(index, index + 500));
    sent += response.successCount;
    skipped += response.failureCount;
  }
  return { noUpiId: false, sent, skipped };
});

exports.onBillWrite = onDocumentWritten("bills/{billId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;
  const data = after || before;
  const uids = data.participantUids || [];

  let title, body;
  if (!before && after) {
    title = "Bill added";
    body = `${data.title} — ₹${data.amount}`;
  } else if (before && after) {
    title = "Bill updated";
    body = `${data.title} — ₹${data.amount}`;
  } else {
    title = "Bill deleted";
    body = `${before.title} — ₹${data.amount} was removed`;
  }

  const tokens = [];
  for (const uid of uids) {
    const u = await admin.firestore().collection("users").doc(uid).get();
    const t = u.data()?.fcmToken;
    if (t) tokens.push(t);
  }
  if (!tokens.length) return;

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
  });
});

exports.monthlyGroupSettleReminders = onSchedule(
  { schedule: "0 10 * * *", timeZone: "Asia/Kolkata" },
  async () => {
    const now = new Date();
    const year = now.getUTCFullYear();
    const month = now.getUTCMonth();
    const today = now.getUTCDate();
    const monthKey = `${year}-${String(month + 1).padStart(2, "0")}`;
    const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();

    const groups = await db
      .collection("groups")
      .where("settleUpDay", ">", 0)
      .get();

    for (const groupDoc of groups.docs) {
      const groupRef = groupDoc.ref;
      const originalData = groupDoc.data();
      const configuredDay = Number(originalData.settleUpDay);
      if (Math.min(configuredDay, lastDay) !== today) continue;

      const groupData = await db.runTransaction(async (transaction) => {
        const latest = await transaction.get(groupRef);
        if (!latest.exists) return null;

        const data = latest.data();
        const latestDay = Number(data.settleUpDay);
        if (
          Math.min(latestDay, lastDay) !== today ||
          data.lastSettleReminderMonth === monthKey
        ) {
          return null;
        }

        transaction.update(groupRef, {
          lastSettleReminderMonth: monthKey,
        });
        return data;
      });
      if (!groupData) continue;

      try {
        const memberUids = [
          ...new Set([groupData.ownerId, ...(groupData.memberUids || [])]),
        ].filter(Boolean);
        if (!memberUids.length) continue;

        const [userDocs, billsSnapshot] = await Promise.all([
          Promise.all(
            memberUids.map((uid) => db.collection("users").doc(uid).get()),
          ),
          db.collection("bills").where("groupId", "==", groupDoc.id).get(),
        ]);

        const tokensByUid = new Map();
        userDocs.forEach((userDoc, index) => {
          const token = userDoc.data()?.fcmToken;
          if (token) tokensByUid.set(memberUids[index], token);
        });
        if (!tokensByUid.size) {
          await groupRef.update({
            lastSettleReminderMonth: admin.firestore.FieldValue.delete(),
          });
          continue;
        }

        const netByUid = new Map(memberUids.map((uid) => [uid, 0]));
        for (const billDoc of billsSnapshot.docs) {
          const bill = billDoc.data();
          const participantUids = bill.participantUids || [];
          const payerUid = bill.paidByUid || bill.ownerId;
          const shares = bill.sharesByUid || {};
          const partialPayments = bill.partialPaymentsByUid || {};
          const remainingFor = (uid) =>
            Math.max(
              0,
              Number(shares[uid] || 0) - Number(partialPayments[uid] || 0),
            );

          for (const uid of memberUids) {
            if (!participantUids.includes(uid)) continue;
            if (uid === payerUid) {
              for (const participantUid of participantUids) {
                if (participantUid !== uid) {
                  netByUid.set(
                    uid,
                    netByUid.get(uid) + remainingFor(participantUid),
                  );
                }
              }
            } else {
              netByUid.set(uid, netByUid.get(uid) - remainingFor(uid));
            }
          }
        }

        const messages = memberUids
          .filter((uid) => tokensByUid.has(uid))
          .map((uid) => {
            const net = netByUid.get(uid) || 0;
            const groupName = groupData.name || "your group";
            let body;
            if (Math.abs(net) <= 0.01) {
              body = `Everything is settled in "${groupName}".`;
            } else if (net > 0) {
              body = `You are owed ₹${net.toFixed(2)} in "${groupName}". Time to settle up.`;
            } else {
              body = `You owe ₹${(-net).toFixed(2)} in "${groupName}". Time to settle up.`;
            }
            return {
              token: tokensByUid.get(uid),
              notification: { title: "Settle up reminder", body },
              data: { groupId: groupDoc.id, type: "group_settle_reminder" },
            };
          });

        for (let index = 0; index < messages.length; index += 500) {
          await admin.messaging().sendEach(messages.slice(index, index + 500));
        }
      } catch (error) {
        await groupRef.update({
          lastSettleReminderMonth: admin.firestore.FieldValue.delete(),
        });
        throw error;
      }
    }
  },
);
