
const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const { registerUser, loginUser } = require("../controllers/authController");
const verifyToken = require("../middlewares/authMiddleware");

// Image upload setup
const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueName + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

// Public login route
router.post("/login", loginUser);

// Secure registration route
router.post("/register", verifyToken, upload.single("profileImage"), registerUser);

module.exports = router;
