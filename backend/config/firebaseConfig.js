const admin = require("firebase-admin");
const serviceAccount = require("./attendance-firebase-adminsdk.json"); // adjust the path if needed

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

module.exports = { admin, db };
