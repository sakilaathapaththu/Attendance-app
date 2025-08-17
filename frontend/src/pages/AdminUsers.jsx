

import React, { useEffect, useState } from "react";
import {
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Chip,
  Card,
  CardContent,
  IconButton,
  Tooltip,
  Fade,
  Grid,
} from "@mui/material";
import AddIcon from "@mui/icons-material/PersonAdd";
import PersonIcon from "@mui/icons-material/Person";
import EmailIcon from "@mui/icons-material/Email";
import BadgeIcon from "@mui/icons-material/Badge";
import AccountCircleIcon from "@mui/icons-material/AccountCircle";
import ContactsIcon from "@mui/icons-material/Contacts";
import LockIcon from "@mui/icons-material/Lock";
import ToggleOnIcon from "@mui/icons-material/ToggleOn";
import ToggleOffIcon from "@mui/icons-material/ToggleOff";
import AdminLayout from "../layouts/AdminLayout";
import axios from "axios";
import { BASE_URL } from "../utils/config";

const AdminUsers = () => {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openModal, setOpenModal] = useState(false);
  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    username: "",
    employeeId: "",
    nic: "",
    password: "",
  });

  // ✅ Get current user with fallback
  const currentUser = JSON.parse(localStorage.getItem("user") || "{}");
  const isSuperadmin = currentUser.adminRole === "superadmin";

  useEffect(() => {
    const fetchEmployees = async () => {
      const token = localStorage.getItem("token");
      try {
        const res = await axios.get(`${BASE_URL}/users`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setEmployees(res.data);
      } catch (error) {
        console.error("Error fetching users:", error);
        alert("Failed to load employees");
      } finally {
        setLoading(false);
      }
    };

    fetchEmployees();
  }, []);

  // ✅ Create new employee with duplicate checks
  const handleCreateEmployee = async () => {
    const { email, username, employeeId, nic } = formData;

    if (employees.some((emp) => emp.email === email)) {
      alert("❌ Email already in use.");
      return;
    }
    if (employees.some((emp) => emp.username === username)) {
      alert("❌ Username already in use.");
      return;
    }
    if (employees.some((emp) => emp.employeeId === employeeId)) {
      alert("❌ Employee ID already exists.");
      return;
    }
    if (employees.some((emp) => emp.nic === nic)) {
      alert("❌ NIC already exists.");
      return;
    }

    try {
      const token = localStorage.getItem("token");
      const form = new FormData();
      Object.entries(formData).forEach(([key, value]) =>
        form.append(key, value)
      );
      form.append("type", "employee");

      await axios.post(`${BASE_URL}/auth/register`, form, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      alert("✅ Employee created successfully!");
      setOpenModal(false);
      setFormData({
        firstName: "",
        lastName: "",
        email: "",
        username: "",
        employeeId: "",
        nic: "",
        password: "",
      });

      window.location.reload();
    } catch (error) {
      console.error("Error creating employee:", error);
      alert(error.response?.data?.error || "Registration failed");
    }
  };

  // 🔁 Toggle employee status (superadmin only)
  const handleToggleStatus = async (uid, currentStatus) => {
    const token = localStorage.getItem("token");
    try {
      const res = await axios.patch(
        `${BASE_URL}/users/${uid}/status`,
        { isActive: !currentStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      alert(res.data.message);
      setEmployees((prev) =>
        prev.map((emp) =>
          emp.uid === uid ? { ...emp, isActive: !currentStatus } : emp
        )
      );
    } catch (err) {
      alert("Failed to update user status");
    }
  };

  const formFields = [
    { field: "firstName", label: "First Name", icon: <PersonIcon /> },
    { field: "lastName", label: "Last Name", icon: <PersonIcon /> },
    { field: "email", label: "Email", icon: <EmailIcon /> },
    { field: "username", label: "Username", icon: <AccountCircleIcon /> },
    { field: "employeeId", label: "Employee ID", icon: <BadgeIcon /> },
    { field: "nic", label: "NIC", icon: <ContactsIcon /> },
    { field: "password", label: "Password", icon: <LockIcon /> },
  ];

  return (
    <AdminLayout>
      <Box sx={{ p: 3, bgcolor: "#f8fbff", minHeight: "100vh" }}>
        {/* Header Section */}
        <Card 
          elevation={0} 
          sx={{ 
            mb: 3, 
            background: "linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)",
            border: "1px solid #e1f5fe"
          }}
        >
          <CardContent>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Box>
                <Typography 
                  variant="h4" 
                  sx={{ 
                    fontWeight: 600, 
                    color: "#0d47a1",
                    mb: 1 
                  }}
                >
                  Employee Management
                </Typography>
                <Typography 
                  variant="body1" 
                  sx={{ color: "#1565c0", opacity: 0.8 }}
                >
                  Manage all registered employees
                </Typography>
              </Box>
              <Button
                variant="contained"
                size="large"
                startIcon={<AddIcon />}
                onClick={() => setOpenModal(true)}
                sx={{
                  background: "linear-gradient(45deg, #2196f3 30%, #21cbf3 90%)",
                  borderRadius: "12px",
                  px: 3,
                  py: 1.5,
                  textTransform: "none",
                  fontSize: "1rem",
                  fontWeight: 600,
                  boxShadow: "0 4px 20px rgba(33, 150, 243, 0.3)",
                  "&:hover": {
                    background: "linear-gradient(45deg, #1976d2 30%, #1cb5e0 90%)",
                    transform: "translateY(-2px)",
                    boxShadow: "0 6px 25px rgba(33, 150, 243, 0.4)",
                  },
                  transition: "all 0.3s ease-in-out"
                }}
              >
                Create New Employee
              </Button>
            </Box>
          </CardContent>
        </Card>

        {/* Create Employee Modal */}
        <Dialog 
          open={openModal} 
          onClose={() => setOpenModal(false)}
          maxWidth="md"
          fullWidth
          TransitionComponent={Fade}
          PaperProps={{
            sx: {
              borderRadius: "16px",
              boxShadow: "0 20px 60px rgba(0, 0, 0, 0.1)",
            }
          }}
        >
          <DialogTitle 
            sx={{ 
              background: "linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)",
              color: "#0d47a1",
              fontWeight: 600,
              fontSize: "1.3rem",
              borderBottom: "1px solid #e1f5fe"
            }}
          >
            Register New Employee
          </DialogTitle>
          <DialogContent sx={{ p: 3, bgcolor: "#fafafa" }}>
            <Grid container spacing={3} sx={{ mt: 1 }}>
              {formFields.map(({ field, label, icon }) => (
                <Grid item xs={12} sm={6} key={field}>
                  <TextField
                    label={label}
                    type={field === "password" ? "password" : "text"}
                    value={formData[field]}
                    onChange={(e) =>
                      setFormData({ ...formData, [field]: e.target.value })
                    }
                    fullWidth
                    required
                    InputProps={{
                      startAdornment: (
                        <Box sx={{ mr: 1, color: "#2196f3" }}>
                          {icon}
                        </Box>
                      ),
                    }}
                    sx={{
                      "& .MuiOutlinedInput-root": {
                        borderRadius: "12px",
                        "&:hover fieldset": {
                          borderColor: "#2196f3",
                        },
                        "&.Mui-focused fieldset": {
                          borderColor: "#1976d2",
                        },
                      },
                      "& .MuiInputLabel-root.Mui-focused": {
                        color: "#1976d2",
                      },
                    }}
                  />
                </Grid>
              ))}
            </Grid>
          </DialogContent>
          <DialogActions sx={{ p: 3, bgcolor: "#fafafa", gap: 1 }}>
            <Button 
              onClick={() => setOpenModal(false)}
              sx={{ 
                borderRadius: "8px",
                color: "#666",
                "&:hover": {
                  bgcolor: "#f5f5f5"
                }
              }}
            >
              Cancel
            </Button>
            <Button 
              onClick={handleCreateEmployee} 
              variant="contained"
              sx={{
                background: "linear-gradient(45deg, #2196f3 30%, #21cbf3 90%)",
                borderRadius: "8px",
                px: 3,
                textTransform: "none",
                fontWeight: 600,
                "&:hover": {
                  background: "linear-gradient(45deg, #1976d2 30%, #1cb5e0 90%)",
                }
              }}
            >
              Create Employee
            </Button>
          </DialogActions>
        </Dialog>

        {/* Employee Table */}
        {loading ? (
          <Card 
            elevation={0} 
            sx={{ 
              border: "1px solid #e1f5fe",
              borderRadius: "16px" 
            }}
          >
            <CardContent>
              <Box 
                display="flex" 
                justifyContent="center" 
                alignItems="center"
                sx={{ py: 8 }}
              >
                <CircularProgress 
                  size={50} 
                  sx={{ color: "#2196f3" }}
                />
              </Box>
            </CardContent>
          </Card>
        ) : (
          <Card 
            elevation={0} 
            sx={{ 
              border: "1px solid #e1f5fe",
              borderRadius: "16px",
              overflow: "hidden"
            }}
          >
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow 
                    sx={{ 
                      background: "linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%)"
                    }}
                  >
                    {["Employee ID", "Full Name", "Email", "Username", "NIC", "Status"].map((header) => (
                      <TableCell 
                        key={header}
                        sx={{ 
                          fontWeight: 700,
                          fontSize: "0.95rem",
                          color: "#0d47a1",
                          borderBottom: "2px solid #90caf9"
                        }}
                      >
                        {header}
                      </TableCell>
                    ))}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {employees.map((emp, index) => (
                    <TableRow 
                      key={emp.uid}
                      sx={{
                        "&:nth-of-type(even)": {
                          bgcolor: "#f8fbff",
                        },
                        "&:hover": {
                          bgcolor: "#e8f4fd",
                          transform: "scale(1.001)",
                        },
                        transition: "all 0.2s ease-in-out"
                      }}
                    >
                      <TableCell sx={{ fontWeight: 500 }}>
                        {emp.employeeId || "-"}
                      </TableCell>
                      <TableCell sx={{ fontWeight: 500 }}>
                        {`${emp.firstName} ${emp.lastName}`}
                      </TableCell>
                      <TableCell sx={{ color: "#1565c0" }}>
                        {emp.email}
                      </TableCell>
                      <TableCell sx={{ fontWeight: 500 }}>
                        {emp.username}
                      </TableCell>
                      <TableCell>
                        {emp.nic || "-"}
                      </TableCell>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Chip
                            label={emp.isActive === false ? "Inactive" : "Active"}
                            size="small"
                            sx={{
                              bgcolor: emp.isActive === false ? "#ffebee" : "#e8f5e8",
                              color: emp.isActive === false ? "#c62828" : "#2e7d32",
                              fontWeight: 600,
                              borderRadius: "8px",
                            }}
                          />
                          {isSuperadmin && (
                            <Tooltip title={emp.isActive ? "Deactivate User" : "Activate User"}>
                              <IconButton
                                size="small"
                                onClick={() => handleToggleStatus(emp.uid, emp.isActive)}
                                sx={{
                                  color: emp.isActive ? "#f44336" : "#4caf50",
                                  "&:hover": {
                                    bgcolor: emp.isActive ? "#ffebee" : "#e8f5e8",
                                  }
                                }}
                              >
                                {emp.isActive ? <ToggleOffIcon /> : <ToggleOnIcon />}
                              </IconButton>
                            </Tooltip>
                          )}
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Card>
        )}
      </Box>
    </AdminLayout>
  );
};

export default AdminUsers;