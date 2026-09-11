const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Fires on any write (create/update/delete) to bills/{billId}.
 * Figures out which case it is, builds title/body, sends FCM to
 * every participantUid (+ group owner/members if groupId set),
 * excluding whoever triggered the write.
 */
exports.onBillWrite = onDocumentWritten("bills/{billId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : null;
  const after = event.data.after.exists ? event.data.after.data() : null;

  let title, body, participantUids, actorUid;

  if (!before && after) {
    // CREATE
    actorUid = after.ownerId;
    participantUids = after.participantUids || [];
    const actorName = await getName(actorUid);
    title = after.groupId ? "New group bill" : "New bill added";
    body = `${actorName} added "${after.title}" for ₹${after.amount}`;

    if (after.groupId) {
      const group = await db.collection("groups").doc(after.groupId).get();
      const members = group.data()?.memberUids || [];
      const ownerId = group.data()?.ownerId;
      participantUids = [...new Set([...participantUids, ...members, ownerId])];
    }
  } else if (before && after) {
    // UPDATE — only notify on real field edits (title/amount/etc),
    // skip settledUids/settledFriendIds churn (too noisy).
    const editedFields = [
      "title",
      "amount",
      "date",
      "friendIds",
      "splitMethod",
      "customAmounts",
      "myShare",
      "paidBy",
      "note",
    ];
    const changed = editedFields.some(
      (f) => JSON.stringify(before[f]) !== JSON.stringify(after[f]),
    );
    if (!changed) return null;

    actorUid = after.ownerId;
    participantUids = after.participantUids || [];
    const actorName = await getName(actorUid);
    title = "Bill updated";
    body = `${actorName} updated "${after.title}"`;
  } else if (before && !after) {
    // DELETE
    actorUid = before.ownerId;
    participantUids = before.participantUids || [];
    const actorName = await getName(actorUid);
    title = "Bill deleted";
    body = `${actorName} deleted "${before.title}"`;
  } else {
    return null;
  }

  const targets = participantUids.filter((uid) => uid !== actorUid);
  if (targets.length === 0) return null;

  const tokens = await getTokens(targets);
  if (tokens.length === 0) return null;

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
  });

  return null;
});

/** Full name of a user, or "Someone" if missing. */
async function getName(uid) {
  const doc = await db.collection("users").doc(uid).get();
  return doc.data()?.fullName || "Someone";
}

/** fcmTokens for a list of uids, skipping any user with no token saved. */
async function getTokens(uids) {
  const tokens = [];
  for (const uid of uids) {
    const doc = await db.collection("users").doc(uid).get();
    const token = doc.data()?.fcmToken;
    if (token) tokens.push(token);
  }
  return tokens;
}
