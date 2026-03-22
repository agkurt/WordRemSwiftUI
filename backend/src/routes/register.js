// backend/src/routes/register.js
// POST /api/register — receives FCM token & uid, schedules notification

const express = require("express");
const { scheduleNotification } = require("../queue/notificationQueue");

const router = express.Router();

/**
 * POST /api/register
 * Body: { fcmToken: string, uid: string }
 *
 * Enqueues a push notification job delayed by NOTIFICATION_DELAY_MS (default 1h)
 */
router.post("/", async (req, res) => {
    const { fcmToken, uid } = req.body;

    // Validate required fields
    if (!fcmToken || typeof fcmToken !== "string" || fcmToken.trim() === "") {
        return res.status(400).json({ error: "fcmToken is required" });
    }
    if (!uid || typeof uid !== "string" || uid.trim() === "") {
        return res.status(400).json({ error: "uid is required" });
    }

    try {
        const job = await scheduleNotification({
            fcmToken: fcmToken.trim(),
            uid: uid.trim(),
            title: "Bizi şimdiden özledin mi? 😢",
            body: "Kelimelerin seni bekliyor, pratik yapmaya ne dersin?",
        });

        return res.status(200).json({
            success: true,
            jobId: job.id,
            message: "Notification scheduled",
            delayMs: parseInt(process.env.NOTIFICATION_DELAY_MS || "3600000"),
        });
    } catch (error) {
        console.error("Failed to schedule notification:", error);
        return res.status(500).json({ error: "Failed to schedule notification" });
    }
});

module.exports = router;
