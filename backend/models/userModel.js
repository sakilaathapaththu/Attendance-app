const { db } = require("../config/firebaseConfig");

const createUserInFirestore = async (userId, userData) => {
  await db.collection("users").doc(userId).set(userData);
};

const getUserByUid = async (uid) => {
  const doc = await db.collection("users").doc(uid).get();
  return doc.exists ? doc.data() : null;
};

module.exports = {
  createUserInFirestore,
  getUserByUid
};
