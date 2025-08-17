// import React, { useState } from "react";
// import {
//   Container,
//   TextField,
//   Button,
//   Typography,
//   Box,
//   Paper,
//   CircularProgress,
//   Alert,
// } from "@mui/material";
// import { loginUser } from "../api/authApi";
// import { useNavigate } from "react-router-dom";

// function Login() {
//   const navigate = useNavigate();
//   const [email, setEmail] = useState("");
//   const [password, setPassword] = useState("");
//   const [message, setMessage] = useState("");
//   const [loading, setLoading] = useState(false);

//   const handleLogin = async () => {
//   setLoading(true);
//   setMessage("");
//   try {
//     const { token, user } = await loginUser(email, password);

//     if (user.type !== "admin") {
//       setMessage("❌ Only admins can access this panel");
//       setLoading(false);
//       return;
//     }

//     localStorage.setItem("token", token);
//     localStorage.setItem("user", JSON.stringify(user)); // ✅ Save full user object

//     setMessage("✅ Login successful!");
//     setTimeout(() => {
//       navigate("/admin-dashboard");
//     }, 1000);
//   } catch (err) {
//     setMessage("❌ " + (err.response?.data?.error || "Login failed"));
//   } finally {
//     setLoading(false);
//   }
// };


//   return (
//     <Container maxWidth="sm">
//       <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
//         <Paper elevation={4} sx={{ p: 4, width: "100%" }}>
//           <Typography variant="h4" align="center" gutterBottom>
//             Admin Login
//           </Typography>

//           <TextField
//             label="Admin Email"
//             type="email"
//             fullWidth
//             margin="normal"
//             value={email}
//             onChange={(e) => setEmail(e.target.value)}
//           />

//           <TextField
//             label="Password"
//             type="password"
//             fullWidth
//             margin="normal"
//             value={password}
//             onChange={(e) => setPassword(e.target.value)}
//           />

//           <Button
//             variant="contained"
//             color="primary"
//             fullWidth
//             onClick={handleLogin}
//             disabled={loading}
//             sx={{ mt: 2 }}
//           >
//             {loading ? <CircularProgress size={24} color="inherit" /> : "Login as Admin"}
//           </Button>

//           {message && (
//             <Alert severity={message.startsWith("✅") ? "success" : "error"} sx={{ mt: 2 }}>
//               {message}
//             </Alert>
//           )}
//         </Paper>
//       </Box>
//     </Container>
//   );
// }

// export default Login;
import React, { useState, useContext } from "react";
import {
  Container,
  TextField,
  Button,
  Typography,
  Box,
  Paper,
  CircularProgress,
  Alert,
} from "@mui/material";
import { loginUser } from "../api/authApi";
import { useNavigate } from "react-router-dom";
import { AuthContext } from "../context/AuthContext"; // ✅ Import context

function Login() {
  const navigate = useNavigate();
  const { setIsAuthenticated } = useContext(AuthContext); // ✅ Get context setter

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    setLoading(true);
    setMessage("");

    try {
      const { token, user } = await loginUser(email, password);

      if (user.type !== "admin") {
        setMessage("❌ Only admins can access this panel");
        setLoading(false);
        return;
      }

      // ✅ Save token and user
      localStorage.setItem("token", token);
      localStorage.setItem("user", JSON.stringify(user));
      setIsAuthenticated(true); // ✅ Update global auth state

      setMessage("✅ Login successful!");
      setTimeout(() => {
        navigate("/admin-dashboard");
      }, 1000);
    } catch (err) {
      setMessage("❌ " + (err.response?.data?.error || "Login failed"));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
        <Paper elevation={4} sx={{ p: 4, width: "100%" }}>
          <Typography variant="h4" align="center" gutterBottom>
            Admin Login
          </Typography>

          <TextField
            label="Admin Email"
            type="email"
            fullWidth
            margin="normal"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          <TextField
            label="Password"
            type="password"
            fullWidth
            margin="normal"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <Button
            variant="contained"
            color="primary"
            fullWidth
            onClick={handleLogin}
            disabled={loading}
            sx={{ mt: 2 }}
          >
            {loading ? <CircularProgress size={24} color="inherit" /> : "Login as Admin"}
          </Button>

          {message && (
            <Alert severity={message.startsWith("✅") ? "success" : "error"} sx={{ mt: 2 }}>
              {message}
            </Alert>
          )}
        </Paper>
      </Box>
    </Container>
  );
}

export default Login;
