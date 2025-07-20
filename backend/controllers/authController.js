
const { admin } = require("../config/firebaseConfig");
const { createUserInFirestore, getUserByUid } = require("../models/userModel");
const axios = require("axios");
const path = require("path");

// 🔐 Admin-only Registration Logic
const registerUser = async (req, res) => {
  try {
    const currentUserUid = req.user?.uid;
    if (!currentUserUid) return res.status(401).json({ error: "Unauthorized: No UID header" });

    const currentUser = await getUserByUid(currentUserUid);

    if (!currentUser || currentUser.type !== "admin") {
      return res.status(403).json({ error: "Access denied: Only admins can register users" });
    }

    const isSuperAdmin = currentUser.adminRole === "superadmin";
    const isEditor = currentUser.adminRole === "editor";

    const {
      firstName,
      lastName,
      email,
      username,
      employeeId,
      nic,
      password,
      type,
      adminRole,
    } = req.body;

    // Admin creation permissions
    if (type === "admin" && !isSuperAdmin) {
      return res.status(403).json({ error: "Only superadmin can create new admins" });
    }

    if (type === "employee" && !["editor", "superadmin"].includes(currentUser.adminRole)) {
      return res.status(403).json({ error: "Only editor or superadmin can create employees" });
    }

    const profileImage = req.file ? `/uploads/${req.file.filename}` : "";

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`,
    });

    const userData = {
  uid: userRecord.uid,
  firstName,
  lastName,
  email,
  username,
  employeeId,
  nic,
  type,
  profileImage,
  createdBy: currentUserUid,
  createdAt: new Date().toISOString(),
  isActive: true, // ← default status
};

    if (type === "admin") {
      userData.adminRole = adminRole || "editor";
    }

    await createUserInFirestore(userRecord.uid, userData);

    res.status(201).json({ message: "User registered successfully", userId: userRecord.uid });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🔑 Login with Firebase Auth REST API
// const loginUser = async (req, res) => {
//   const { email, password } = req.body;

//   try {
//     const response = await axios.post(
//       `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_API_KEY}`,
//       {
//         email,
//         password,
//         returnSecureToken: true,
//       }
//     );

//     const { idToken, localId } = response.data;

//     const userData = await getUserByUid(localId);
//     if (!userData) return res.status(404).json({ error: "User not found in Firestore" });

//     res.status(200).json({
//       message: "Login successful",
//       user: userData,
//       token: idToken,
//     });
//   } catch (error) {
//     const msg = error.response?.data?.error?.message || error.message;
//     res.status(401).json({ error: msg });
//   }
// };
const loginUser = async (req, res) => {
  const { email, password } = req.body;

  try {
    const response = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_API_KEY}`,
      {
        email,
        password,
        returnSecureToken: true,
      }
    );

    const { idToken, localId } = response.data;

    const userData = await getUserByUid(localId);
    if (!userData) return res.status(404).json({ error: "User not found in Firestore" });

    // ✅ Add UID into returned user object
    const fullUser = { ...userData, uid: localId };

    res.status(200).json({
      message: "Login successful",
      user: fullUser, // this must contain adminRole
      token: idToken,
    });
  } catch (error) {
    const msg = error.response?.data?.error?.message || error.message;
    res.status(401).json({ error: msg });
  }
};


module.exports = {
  registerUser,
  loginUser,
};
