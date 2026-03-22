// backend/src/firebase.js
// Firebase Admin SDK initialization

require("dotenv").config({ path: require("path").join(__dirname, "../../.env") });
const admin = require("firebase-admin");
const path = require("path");

const serviceAccountPath = path.resolve(
    __dirname,
    "../",
    process.env.SERVICE_ACCOUNT_PATH || "./serviceAccount.json"
);

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(require(serviceAccountPath)),
    });
}

module.exports = admin;
