// const express = require("express");
// const cors = require("cors");
// const dotenv = require("dotenv");
// const authRoutes = require("./routes/authRoutes");
// const attendanceRoutes = require("./routes/attendanceRoutes");
// const userRoutes = require("./routes/userRoutes");

// dotenv.config();
// const app = express();
// const PORT = process.env.PORT || 5000;

// // ✅ Middlewares
// app.use(cors());
// app.use(express.json()); // Instead of bodyParser
// app.use(express.urlencoded({ extended: true }));
// app.use("/uploads", express.static("uploads"));

// // ✅ Routes
// app.use("/api/auth", authRoutes);
// app.use("/api/attendance", attendanceRoutes);
// app.use("/api/users", userRoutes);

// // ✅ Health Check
// app.get("/", (req, res) => {
//   res.send("Attendance App Backend is Running");
// });

// // ✅ Start Server
// app.listen(PORT, () => {
//   console.log(`Server started on http://localhost:${PORT}`);
// });
// backend/server.js

const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const authRoutes = require("./routes/authRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const userRoutes = require("./routes/userRoutes");

// ✅ ensure Firebase Admin loads (and fails fast if envs are missing)
require("./config/firebaseConfig");

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;

// ✅ Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/users", userRoutes);

// ✅ Health Check
app.get("/", (req, res) => {
  res.send("Attendance App Backend is Running");
});

// 👉 Export for Vercel
module.exports = app;

// ✅ Start Server (local only)
if (require.main === module && !process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`Server started on http://localhost:${PORT}`);
  });
}
