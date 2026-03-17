// backend/src/index.js
// Express server entry point

require("dotenv").config({ path: require("path").join(__dirname, "../.env") });
const express = require("express");

const registerRoute = require("./routes/register");
// Import queue to start the worker on server boot
require("./queue/notificationQueue");

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(express.json());

// Basic request logger
app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// ─── Routes ───────────────────────────────────────────────────────────────────
app.get("/health", (_req, res) => res.json({ status: "ok", timestamp: new Date().toISOString() }));

app.use("/api/register", registerRoute);

// 404 handler
app.use((_req, res) => res.status(404).json({ error: "Not found" }));

// Global error handler
app.use((err, _req, res, _next) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ error: "Internal server error" });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`
🚀 WordRem Notification Backend running
   → http://localhost:${PORT}
   → POST http://localhost:${PORT}/api/register
   → GET  http://localhost:${PORT}/health
  `);
});
