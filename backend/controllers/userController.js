// module.exports = { getAllUsers };
const { db } = require("../config/firebaseConfig");
const { getUserByUid } = require("../models/userModel");

// ✅ Add this function before exporting
const getAllUsers = async (req, res) => {
  try {
    const snapshot = await db.collection("users").get();
    const users = snapshot.docs
      .map((doc) => ({ uid: doc.id, ...doc.data() }))
      .filter((u) => u.type === "employee");
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch users" });
  }
};


const updateUserStatus = async (req, res) => {
  try {
    const currentUserUid = req.user?.uid;
    const targetUid = req.params.uid;
    const { isActive } = req.body;

    const currentUser = await getUserByUid(currentUserUid);
    if (!currentUser || currentUser.adminRole !== "superadmin") {
      return res.status(403).json({ error: "Only superadmins can update employee status" });
    }

    await db.collection("users").doc(targetUid).update({ isActive });

    res.status(200).json({ message: `User ${isActive ? "activated" : "deactivated"} successfully` });
  } catch (error) {
    console.error("Status update error:", error);
    res.status(500).json({ error: "Failed to update status" });
  }
};

module.exports = { getAllUsers, updateUserStatus };
