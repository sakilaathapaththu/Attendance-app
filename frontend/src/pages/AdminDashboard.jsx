import React from "react";
import { Typography } from "@mui/material";
import AdminLayout from "../layouts/AdminLayout";

function AdminDashboard() {
  return (
    <AdminLayout>
      <Typography variant="h4" gutterBottom>
        Welcome to the Admin Dashboard
      </Typography>
      <Typography variant="body1">
        Here you can view site stats, control users, and manage data.
      </Typography>
    </AdminLayout>
  );
}

export default AdminDashboard;
