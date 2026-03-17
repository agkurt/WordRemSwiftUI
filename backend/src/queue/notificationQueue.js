// backend/src/queue/notificationQueue.js
// BullMQ Queue + Worker for delayed push notifications

require("dotenv").config({ path: require("path").join(__dirname, "../../../.env") });
const { Queue, Worker } = require("bullmq");
const IORedis = require("ioredis");
const admin = require("../firebase");

// ─── Redis connection ──────────────────────────────────────────────────────────
const redisConnection = new IORedis({
    host: process.env.REDIS_HOST || "127.0.0.1",
    port: parseInt(process.env.REDIS_PORT || "6379"),
    password: process.env.REDIS_PASSWORD || undefined,
    maxRetriesPerRequest: null, // required by BullMQ
});

redisConnection.on("connect", () => console.log("✅ Redis connected"));
redisConnection.on("error", (err) => console.error("❌ Redis error:", err.message));

// ─── Queue ─────────────────────────────────────────────────────────────────────
const QUEUE_NAME = "push-notifications";

const notificationQueue = new Queue(QUEUE_NAME, {
    connection: redisConnection,
    defaultJobOptions: {
        removeOnComplete: 100, // keep last 100 completed jobs
        removeOnFail: 200,
    },
});

// ─── Worker ────────────────────────────────────────────────────────────────────
const notificationWorker = new Worker(
    QUEUE_NAME,
    async (job) => {
        const { fcmToken, uid, title, body } = job.data;
        console.log(`🔔 Sending notification to uid=${uid} | token=${fcmToken.slice(0, 20)}...`);

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
        };

        try {
            const response = await admin.messaging().send(message);
            console.log(`✅ Notification sent: ${response}`);
            return response;
        } catch (error) {
            console.error(`❌ Failed to send notification: ${error.message}`);
            throw error; // BullMQ will retry per job config
        }
    },
    {
        connection: redisConnection,
        concurrency: 10,
    }
);

notificationWorker.on("completed", (job) => {
    console.log(`✅ Job ${job.id} completed`);
});

notificationWorker.on("failed", (job, err) => {
    console.error(`❌ Job ${job.id} failed: ${err.message}`);
});

// ─── Schedule helper ──────────────────────────────────────────────────────────
/**
 * Schedules a push notification with a delay.
 * @param {string} fcmToken - Device FCM token
 * @param {string} uid - Firebase user UID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {number} delayMs - Delay in milliseconds (default: 1 hour = 3600000)
 */
async function scheduleNotification({ fcmToken, uid, title, body, delayMs }) {
    const delay = delayMs ?? parseInt(process.env.NOTIFICATION_DELAY_MS || "3600000");
    const job = await notificationQueue.add(
        "send-delayed-notification",
        { fcmToken, uid, title, body },
        { delay }
    );
    console.log(
        `📅 Job ${job.id} scheduled for uid=${uid} in ${delay / 1000}s (${delay / 3600000}h)`
    );
    return job;
}

module.exports = { scheduleNotification, notificationQueue, notificationWorker };
