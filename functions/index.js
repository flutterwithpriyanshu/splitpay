"use strict";

const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

const uniqueValues = (values = []) => [
  ...new Set((values || []).filter(Boolean)),
];

const getRecipients = async (uids = []) => {
  const members = uniqueValues(uids);
  if (!members.length) {
    return [];
  }

  const tokens = [];
  for (let index = 0; index < members.length; index += 10) {
    const chunk = members.slice(index, index + 10);
    const snapshot = await admin
      .firestore()
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", chunk)
      .get();

    snapshot.forEach((doc) => {
      const token = doc.get("fcmToken");
      if (token) {
        tokens.push(token);
      }
    });
  }

  return uniqueValues(tokens);
};

const sendNotifications = async (uids, title, body, data = {}) => {
  const recipients = await getRecipients(uids);
  if (!recipients.length) {
    return null;
  }

  const payload = {
    notification: {
      title,
      body,
    },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)]),
    ),
  };

  return admin.messaging().sendEachForMulticast({
    tokens: recipients,
    ...payload,
  });
};

const toParticipantList = (data = {}) => {
  const values = [];
  const lists = [
    data.participantUids,
    data.friendIds,
    data.groupMemberUids,
    data.memberUids,
    data.ownerId ? [data.ownerId] : [],
  ];

  for (const list of lists) {
    if (Array.isArray(list)) {
      values.push(...list);
    }
  }

  return uniqueValues(values);
};

exports.onBillWrite = functions.firestore
  .document("bills/{billId}")
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    if (!before && !after) {
      return null;
    }

    const payloadData = after || before || {};
    const triggerType =
      before && after ? "updated" : after ? "created" : "deleted";
    const participants = toParticipantList(payloadData);

    if (!participants.length) {
      return null;
    }

    const title = "Bill update";
    const body =
      triggerType === "deleted"
        ? "A bill was removed."
        : triggerType === "updated"
          ? "A bill was updated."
          : "A new bill was added.";

    return sendNotifications(participants, title, body, {
      billId: context.params.billId,
      type: triggerType,
    });
  });

exports.onBillDelete = functions.firestore
  .document("bills/{billId}")
  .onDelete(async (snapshot, context) => {
    const data = snapshot.data() || {};
    const participants = toParticipantList(data);

    if (!participants.length) {
      return null;
    }

    return sendNotifications(
      participants,
      "Bill removed",
      "A bill was deleted.",
      {
        billId: context.params.billId,
        type: "deleted",
      },
    );
  });

exports.sendBillNotification = functions.https.onCall(async (data) => {
  const {
    participants = [],
    title = "Bill update",
    body = "There is a bill update.",
    billId = "",
    type = "updated",
  } = data || {};

  if (!Array.isArray(participants) || participants.length === 0) {
    return { sent: 0 };
  }

  const result = await sendNotifications(participants, title, body, {
    billId,
    type,
  });

  return {
    sent: result?.successCount ?? 0,
  };
});
