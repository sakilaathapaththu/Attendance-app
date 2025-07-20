// routes/userRoutes.js
const express = require("express");
const router = express.Router();
const { getAllUsers, updateUserStatus } = require("../controllers/userController"); // ✅ Fix here
const verifyToken = require("../middlewares/authMiddleware");


router.get("/", verifyToken, getAllUsers); // GET /users
router.patch("/:uid/status", verifyToken, updateUserStatus); // PATCH /users/:uid/status

module.exports = router;
