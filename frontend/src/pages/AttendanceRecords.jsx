
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
  TextField,
  InputAdornment,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import AddIcon from "@mui/icons-material/PersonAdd";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import AdminLayout from "../layouts/AdminLayout";
import axios from "axios";
import { BASE_URL } from "../utils/config";
import L from "leaflet";

// Fix marker icon issue
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl:
    "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
});

// Format duration
function formatTimeRange(start, end) {
  if (!start?._seconds || !end?._seconds) return "-";
  const startTime = new Date(start._seconds * 1000);
  const endTime = new Date(end._seconds * 1000);
  const durationMs = endTime - startTime;
  const durationHours = (durationMs / (1000 * 60 * 60)).toFixed(2);
  return `${durationHours} hrs`;
}
export default function AttendanceRecords() {
 const [allRecords, setAllRecords] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedDate, setSelectedDate] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  

  useEffect(() => {
    axios
      .get(`${BASE_URL}/attendance`)
      .then((res) => setAllRecords(res.data))
      .catch((err) => console.error("Error fetching attendance:", err))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    let results = [];

    if (selectedDate) {
      results = allRecords.filter((entry) => entry.date === selectedDate);
    } else {
      // Latest per user
      const grouped = {};
      allRecords.forEach((entry) => {
        const uid = entry.user?.employeeId || entry.userId;
        if (!grouped[uid]) grouped[uid] = [];
        grouped[uid].push(entry);
      });

      results = Object.values(grouped).map((records) =>
        records.sort(
          (a, b) => (b.startTime?._seconds || 0) - (a.startTime?._seconds || 0)
        )[0]
      );
    }

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      results = results.filter((entry) => {
        const fullName = `${entry.user?.firstName || ""} ${entry.user?.lastName || ""}`.toLowerCase();
        return (
          entry.user?.employeeId?.toLowerCase().includes(q) ||
          fullName.includes(q) ||
          entry.user?.email?.toLowerCase().includes(q)
        );
      });
    }

    setFiltered(results);
  }, [selectedDate, searchQuery, allRecords]);

  

  return (
    <AdminLayout>
      <Typography variant="h5" gutterBottom>
        Attendance Records {selectedDate ? `(on ${selectedDate})` : "(Latest per User)"}
      </Typography>

      <Box display="flex" justifyContent="space-between" gap={2} mb={2}>
        <TextField
          type="date"
          label="Filter by Date"
          size="small"
          InputLabelProps={{ shrink: true }}
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
        />
        <TextField
          placeholder="Search by name / employee ID / email"
          variant="outlined"
          size="small"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ flexGrow: 1 }}
        />
        
      </Box>

      

      {/* Attendance Table */}
      {loading ? (
        <Box display="flex" justifyContent="center" my={4}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Employee ID</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Start Time</TableCell>
                <TableCell>End Time</TableCell>
                <TableCell>Duration</TableCell>
                <TableCell>Start Location</TableCell>
                <TableCell>End Location</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.map((entry, idx) => (
                <TableRow key={idx}>
                  <TableCell>{entry.user?.employeeId || "-"}</TableCell>
                  <TableCell>
                    {entry.user?.firstName && entry.user?.lastName
                      ? `${entry.user.firstName} ${entry.user.lastName}`
                      : "-"}
                  </TableCell>
                  <TableCell>{entry.user?.email || "-"}</TableCell>
                  <TableCell>{entry.date || "-"}</TableCell>
                  <TableCell>
                    {entry.startTime
                      ? new Date(entry.startTime._seconds * 1000).toLocaleTimeString()
                      : "-"}
                  </TableCell>
                  <TableCell>
                    {entry.endTime
                      ? new Date(entry.endTime._seconds * 1000).toLocaleTimeString()
                      : "-"}
                  </TableCell>
                  <TableCell>
                    {formatTimeRange(entry.startTime, entry.endTime)}
                  </TableCell>
                  <TableCell>
                    {entry.startLocation?.latitude &&
                    entry.startLocation?.longitude ? (
                      <MapContainer
                        center={[
                          entry.startLocation.latitude,
                          entry.startLocation.longitude,
                        ]}
                        zoom={13}
                        style={{ height: "100px", width: "100%" }}
                      >
                        <TileLayer
                          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                          attribution='&copy; OpenStreetMap contributors'
                        />
                        <Marker
                          position={[
                            entry.startLocation.latitude,
                            entry.startLocation.longitude,
                          ]}
                        >
                          <Popup>Start Location</Popup>
                        </Marker>
                      </MapContainer>
                    ) : (
                      "-"
                    )}
                  </TableCell>
                  <TableCell>
                    {entry.endLocation?.latitude &&
                    entry.endLocation?.longitude ? (
                      <MapContainer
                        center={[
                          entry.endLocation.latitude,
                          entry.endLocation.longitude,
                        ]}
                        zoom={13}
                        style={{ height: "100px", width: "100%" }}
                      >
                        <TileLayer
                          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                          attribution='&copy; OpenStreetMap contributors'
                        />
                        <Marker
                          position={[
                            entry.endLocation.latitude,
                            entry.endLocation.longitude,
                          ]}
                        >
                          <Popup>End Location</Popup>
                        </Marker>
                      </MapContainer>
                    ) : (
                      "-"
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </AdminLayout>
  );
};
