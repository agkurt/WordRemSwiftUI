const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { CloudTasksClient } = require("@google-cloud/tasks");
const cors = require('cors')({ origin: true });

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "wordrem-ce662"
});
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────────────────
// 1. FIRESTORE-TRIGGERED: fires when a doc is created in `notifications/{notifId}`
//
//    Expected document shape:
//    {
//      uid: string,       // target user's Firebase UID
//      title: string,     // notification title
//      body: string,      // notification body
//      data?: object      // optional extra payload
//    }
// ─────────────────────────────────────────────────────────────────────────────
exports.sendNotificationOnTrigger = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const { uid, title, body, data } = snap.data();

    if (!uid || !title || !body) {
      console.error("Missing required fields: uid, title, body");
      return null;
    }

    // Get the user's FCM token from Firestore
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      console.error(`User document not found for uid: ${uid}`);
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.error(`No FCM token found for uid: ${uid}`);
      return null;
    }

    const message = {
      token: fcmToken,
      notification: { title, body },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            badge: 1,
            sound: "default",
          },
        },
      },
      data: data || {},
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Notification sent:", response);

      // Mark the notification document as sent
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      await snap.ref.update({ sent: false, error: error.message });
      return null;
    }
  });

// ─────────────────────────────────────────────────────────────────────────────
// 2. HTTP CALLABLE: call from Swift with Functions.functions().httpsCallable("sendToUser")
//
//    Swift usage:
//      let functions = Functions.functions()
//      functions.httpsCallable("sendToUser").call(["uid": uid, "title": "Hello", "body": "World"])
//
//    Request payload:
//    {
//      uid: string,
//      title: string,
//      body: string,
//      data?: object
//    }
// ─────────────────────────────────────────────────────────────────────────────
exports.sendToUser = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to send notifications."
    );
  }

  const { uid, title, body } = data;
  if (!uid || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "uid, title, and body are required."
    );
  }

  // Get target user's FCM token
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || !userDoc.data().fcmToken) {
    throw new functions.https.HttpsError(
      "not-found",
      `No FCM token found for uid: ${uid}`
    );
  }

  const fcmToken = userDoc.data().fcmToken;
  const message = {
    token: fcmToken,
    notification: { title, body },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          badge: 1,
          sound: "default",
        },
      },
    },
    data: data.data || {},
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("sendToUser sent:", response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error("sendToUser error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. HELPER: broadcast notification to ALL users (use with care)
//
//    HTTP callable: functions.httpsCallable("broadcastNotification")
//    Request: { title: string, body: string, data?: object }
// ─────────────────────────────────────────────────────────────────────────────
exports.broadcastNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
  }

  const { title, body } = data;
  if (!title || !body) {
    throw new functions.https.HttpsError("invalid-argument", "title and body are required.");
  }

  // Collect all FCM tokens from users collection
  const usersSnapshot = await db.collection("users").get();
  const tokens = [];
  usersSnapshot.forEach((doc) => {
    const token = doc.data().fcmToken;
    if (token) tokens.push(token);
  });

  if (tokens.length === 0) {
    return { success: false, message: "No FCM tokens found." };
  }

  // Send in batches of 500 (FCM multicast limit)
  const batchSize = 500;
  const results = [];
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    const multicast = {
      tokens: batch,
      notification: { title, body },
      apns: {
        payload: { aps: { alert: { title, body }, badge: 1, sound: "default" } },
      },
    };
    const result = await admin.messaging().sendEachForMulticast(multicast);
    results.push(result);
  }

  const totalSuccess = results.reduce((sum, r) => sum + r.successCount, 0);
  const totalFailed = results.reduce((sum, r) => sum + r.failureCount, 0);
  console.log(`Broadcast: ${totalSuccess} sent, ${totalFailed} failed`);
  return { success: true, sent: totalSuccess, failed: totalFailed };
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. HTTP REQUEST: Logout notification (15s delay using Cloud Tasks)
// ─────────────────────────────────────────────────────────────────────────────
exports.triggerLogoutNotification = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") return res.status(405).send("Sadece POST metoduna izin verilmektedir.");

    const { fcmToken, uid, title, body } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ error: "fcmToken parametresi zorunludur." });
    }

    // --- CONFIGURATION ---
    const project = "wordrem-ce662"; // WordRem Firebase Project ID
    const location = "us-central1";
    const queue = "notifications-queue";

    // The endpoint that Cloud Tasks will call after 15 seconds to physically send the push
    const url = `https://${location}-${project}.cloudfunctions.net/sendDelayedPushTest`;

    const payload = {
      fcmToken,
      uid,
      title: title || "Bizi şimdiden özledin mi? �",
      body: body || "Kelimelerin seni bekliyor, pratik yapmaya ne dersin?"
    };

    const client = new CloudTasksClient();
    const parent = client.queuePath(project, location, queue);

    const delayInSeconds = 15;
    const scheduleTime = Math.floor(Date.now() / 1000) + delayInSeconds;

    const task = {
      httpRequest: {
        httpMethod: "POST",
        url: url,
        body: Buffer.from(JSON.stringify(payload)).toString("base64"),
        headers: { "Content-Type": "application/json" },
      },
      scheduleTime: {
        seconds: scheduleTime,
      },
    };

    try {
      const [response] = await client.createTask({ parent, task });
      console.log(`Cloud Task created successfully: ${response.name}`);
      return res.status(200).json({ success: true, message: "Test kaydı alındı, 15 saniye sonra bildirim atılacak." });
    } catch (error) {
      console.error("Cloud Task oluşturma hatası:", error);
      return res.status(500).json({ error: error.message });
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. HTTP Endpoint: The actual Push Notification executor for Cloud Tasks
// ─────────────────────────────────────────────────────────────────────────────
exports.sendDelayedPushTest = functions.https.onRequest(async (req, res) => {
  const { fcmToken, uid, title, body } = req.body;

  if (!fcmToken) {
    return res.status(400).send("Geçersiz fcmToken.");
  }

  const message = {
    token: fcmToken,
    notification: {
      title: title || "Bizi şimdiden özledin mi? �",
      body: body || "Kelimelerin seni bekliyor, pratik yapmaya ne dersin?"
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("15 saniyelik test bildirimi BAŞARIYLA atıldı:", response);
    return res.status(200).send("Test Bildirimi Başarıyla Gönderildi.");
  } catch (error) {
    console.error("Firebase FCM Gönderim Hatası:", error);
    return res.status(500).send("FCM Hatası: " + error.message);
  }
});
