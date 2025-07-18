const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const { registerUser, loginUser } = require("../controllers/authController");
const verifyToken = require("../middlewares/authMiddleware");

const storage = multer.diskStorage({
  destination: "uploads/",
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

router.post("/register", verifyToken, upload.single("profileImage"), registerUser);
router.post("/login", loginUser);

module.exports = router;
