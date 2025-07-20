const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const dotenv = require("dotenv");
const authRoutes = require("./routes/authRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());
app.use("/uploads", express.static("uploads"));

app.use("/api/auth", authRoutes);

app.use("/api/attendance", attendanceRoutes);

app.use("/api/users", require("./routes/userRoutes"));

app.get("/", (req, res) => {
  res.send("Attendance App Backend is Running");
});

app.listen(PORT, () => {
  console.log(`Server started on http://localhost:${PORT}`);
});
