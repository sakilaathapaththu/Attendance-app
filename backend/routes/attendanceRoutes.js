// routes/attendanceRoutes.js

const express = require("express");
const router = express.Router();
const { getAllAttendance } = require("../controllers/attendanceController");

router.get("/", getAllAttendance); // GET /api/attendance

module.exports = router;
