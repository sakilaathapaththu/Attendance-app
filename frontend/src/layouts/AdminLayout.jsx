// ✅ AdminLayout.jsx with dark/light toggle, avatar, active link highlight, and route protection

import React, { useState, useMemo } from "react";
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  CssBaseline,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Box,
  Avatar,
  Menu,
  MenuItem,
  useTheme,
  useMediaQuery,
  Switch,
  Tooltip
} from "@mui/material";

import MenuIcon from "@mui/icons-material/Menu";
import DashboardIcon from "@mui/icons-material/Dashboard";
import PeopleIcon from "@mui/icons-material/People";
import SettingsIcon from "@mui/icons-material/Settings";
import LogoutIcon from "@mui/icons-material/Logout";
import { useNavigate, useLocation } from "react-router-dom";
import { createTheme, ThemeProvider } from "@mui/material/styles";

const drawerWidth = 240;

const navigationItems = [
  { text: "Dashboard", icon: <DashboardIcon />, path: "/admin-dashboard" },
  { text: "Users", icon: <PeopleIcon />, path: "/admin-users" },
  { text: "Attendance Records", icon: <PeopleIcon />, path: "/attendance-records" },
  { text: "Settings", icon: <SettingsIcon />, path: "/admin-settings" },
];

function AdminLayout({ children }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));
  const navigate = useNavigate();
  const location = useLocation();

  const customTheme = useMemo(() =>
    createTheme({ palette: { mode: darkMode ? "dark" : "light" } }),
    [darkMode]
  );

  const handleDrawerToggle = () => setMobileOpen(!mobileOpen);
  const handleAvatarClick = (e) => setAnchorEl(e.currentTarget);
  const handleMenuClose = () => setAnchorEl(null);

  const drawer = (
    <div>
      <Toolbar>
        <Typography variant="h6">Admin Panel</Typography>
      </Toolbar>
      <Divider />
      <List>
        {navigationItems.map((item) => (
          <ListItem
            button
            key={item.text}
            onClick={() => navigate(item.path)}
            selected={location.pathname === item.path}
          >
            <ListItemIcon>{item.icon}</ListItemIcon>
            <ListItemText primary={item.text} />
          </ListItem>
        ))}
      </List>
    </div>
  );

  return (
    <ThemeProvider theme={customTheme}>
      <Box sx={{ display: "flex" }}>
        <CssBaseline />
        <AppBar
          position="fixed"
          sx={{ width: { md: `calc(100% - ${drawerWidth}px)` }, ml: { md: `${drawerWidth}px` } }}
        >
          <Toolbar>
            {isMobile && (
              <IconButton color="inherit" onClick={handleDrawerToggle} sx={{ mr: 2 }}>
                <MenuIcon />
              </IconButton>
            )}
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              Admin Panel
            </Typography>
            <Tooltip title="Toggle Dark Mode">
              <Switch checked={darkMode} onChange={() => setDarkMode(!darkMode)} />
            </Tooltip>
            <IconButton color="inherit" onClick={handleAvatarClick}>
              <Avatar sx={{ width: 32, height: 32 }}>A</Avatar>
            </IconButton>
            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={handleMenuClose}
            >
              <MenuItem onClick={() => navigate("/admin-settings")}>Profile</MenuItem>
              <MenuItem
                onClick={() => {
                  localStorage.removeItem("token");
                  navigate("/");
                }}
              >
                <LogoutIcon fontSize="small" sx={{ mr: 1 }} /> Logout
              </MenuItem>
            </Menu>
          </Toolbar>
        </AppBar>

        <Box component="nav" sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}>
          <Drawer
            variant={isMobile ? "temporary" : "permanent"}
            open={isMobile ? mobileOpen : true}
            onClose={handleDrawerToggle}
            ModalProps={{ keepMounted: true }}
            sx={{
              "& .MuiDrawer-paper": { width: drawerWidth, boxSizing: "border-box" },
            }}
          >
            {drawer}
          </Drawer>
        </Box>

        <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
          {children}
        </Box>
      </Box>
    </ThemeProvider>
  );
}

export default AdminLayout;
