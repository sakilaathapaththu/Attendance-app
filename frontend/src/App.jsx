import { BrowserRouter, Routes, Route } from "react-router-dom";
import Login from "./pages/Login";
import AdminDashboard from "./pages/AdminDashboard";
import AdminUsers from "./pages/AdminUsers"; // new
import AttendanceRecords from "./pages/AttendanceRecords";
// import AdminSettings from "./pages/AdminSettings"; // optional

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route
          path="/admin-dashboard"
          element={
            localStorage.getItem("token") ? (
              <AdminDashboard />
            ) : (
              <Navigate to="/" />
            )
          }
        />
        <Route path="/admin-users" element={<AdminUsers />} />
        <Route path="/attendance-records" element={<AttendanceRecords />} />
        {/* <Route path="/admin-settings" element={<AdminSettings />} /> */}
      </Routes>
    </BrowserRouter>
  );
}

export default App;
