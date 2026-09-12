const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

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
