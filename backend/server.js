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

// backend/server.js
const dotenv = require("dotenv");
// ✅ Load env first (so firebaseConfig sees them)
dotenv.config();

const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const userRoutes = require("./routes/userRoutes");

// ✅ Initialize Firebase Admin after env is loaded
require("./config/firebaseConfig");

const app = express();
const PORT = process.env.PORT || 5000;
const isServerless = !!process.env.VERCEL || !!process.env.AWS_LAMBDA_FUNCTION_NAME;

// ✅ Middlewares
app.use(
  cors({
    // Optional: lock this down in prod
    origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : true,
    credentials: true,
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Local-only static folder (Vercel uses Blob URLs instead)
if (!isServerless) {
  app.use("/uploads", express.static("uploads"));
}

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/users", userRoutes);

// ✅ Health Check
app.get("/", (_req, res) => {
  res.send("Attendance App Backend is Running");
});

// 👉 Export for Vercel
module.exports = app;

// ✅ Start Server (local only)
if (require.main === module && !isServerless) {
  app.listen(PORT, () => {
    console.log(`Server started on http://localhost:${PORT}`);
  });
}
