
// controllers/attendanceController.js
const { db } = require("../config/firebaseConfig");

// Get all attendance records with user details
const getAllAttendance = async (req, res) => {
  try {
    const attendanceSnapshot = await db.collection("attendance").get();
    const userSnapshot = await db.collection("users").get();

    // Build UID-to-user map
    const userMap = {};
    userSnapshot.forEach((doc) => {
      userMap[doc.id] = doc.data();
    });

    // Build enriched attendance list
    const attendanceData = attendanceSnapshot.docs.map((doc) => {
      const data = doc.data();
      const user = userMap[data.userId] || {};
      return {
        id: doc.id,
        ...data,
        user: {
          employeeId: user.employeeId || "-",
          firstName: user.firstName || "",
          lastName: user.lastName || "",
        },
      };
    });

    res.status(200).json(attendanceData);
  } catch (error) {
    console.error("Error fetching attendance data:", error);
    res.status(500).json({ error: "Failed to fetch attendance data" });
  }
};

module.exports = {
  getAllAttendance,
};
