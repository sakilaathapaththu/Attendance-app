
// const express = require("express");
// const router = express.Router();
// const multer = require("multer");
// const path = require("path");
// const { registerUser, loginUser } = require("../controllers/authController");
// const verifyToken = require("../middlewares/authMiddleware");

// // Image upload setup
// const storage = multer.diskStorage({
//   destination: "uploads/",
//   filename: (req, file, cb) => {
//     const uniqueName = Date.now() + "-" + Math.round(Math.random() * 1e9);
//     cb(null, uniqueName + path.extname(file.originalname));
//   },
// });
// const upload = multer({ storage });

// // Public login route
// router.post("/login", loginUser);

// // Secure registration route
// router.post("/register", verifyToken, upload.single("profileImage"), registerUser);

// module.exports = router;
const express = require("express");
const router = express.Router();
const multer = require("multer");
const { registerUser, loginUser } = require("../controllers/authController");
const verifyToken = require("../middlewares/authMiddleware");

// --- Multer: keep file in RAM, not disk ---
const storage = multer.memoryStorage();
const fileFilter = (req, file, cb) => {
  if (/^image\/(png|jpe?g|webp|gif|bmp|svg\+xml)$/.test(file.mimetype)) cb(null, true);
  else cb(new Error("Only image files are allowed"), false);
};
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter,
});

// Public login
router.post("/login", loginUser);

// Secure registration (admin-only)
router.post("/register", verifyToken, upload.single("profileImage"), registerUser);

module.exports = router;
