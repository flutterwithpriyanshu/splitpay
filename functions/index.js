const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

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
