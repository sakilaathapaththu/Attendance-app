import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Load user data with better error handling
  Future<String> loadUserData() async {
    try {
      User? user = currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          return data?['username'] ?? '';
        }
      }
      return '';
    } catch (e) {
      print('Error loading user data: $e');
      return '';
    }
  }

  // Get current location with timeout
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Add timeout to prevent indefinite waiting
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10), 
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Check today's attendance status with better error handling
  Future<Map<String, dynamic>> checkTodayAttendance() async {
    try {
      User? user = currentUser;
      if (user == null) {
        return {'isStarted': false, 'startTime': null, 'isCompleted': false};
      }

      DateTime today = DateTime.now();
      String todayString = DateFormat('yyyy-MM-dd').format(today);

      QuerySnapshot attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayString)
          .limit(1) 
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        var doc = attendanceQuery.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        
        bool hasClockOut = data['endTime'] != null;
        DateTime? startTime = data['startTime'] != null 
            ? (data['startTime'] as Timestamp).toDate() 
            : null;
        DateTime? endTime = data['endTime'] != null 
            ? (data['endTime'] as Timestamp).toDate() 
            : null;

        return {
          'isStarted': !hasClockOut,
          'startTime': startTime,
          'endTime': endTime,
          'isCompleted': hasClockOut,
          'docId': doc.id,
        };
      }

      return {'isStarted': false, 'startTime': null, 'isCompleted': false};
    } catch (e) {
      print('Error checking today\'s attendance: $e');
      return {'isStarted': false, 'startTime': null, 'isCompleted': false};
    }
  }

  // Clock in with better error handling and timeout
  Future<Map<String, dynamic>> clockIn() async {
    try {
      User? user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      DateTime now = DateTime.now();
      String todayString = DateFormat('yyyy-MM-dd').format(now);

      // Check if already clocked in today
      QuerySnapshot existingAttendance = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayString)
          .limit(1)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        var doc = existingAttendance.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        
        // If already has clock out, user completed today
        if (data['endTime'] != null) {
          return {'success': false, 'message': 'You have already completed attendance for today'};
        }
        
        // If no clock out, already clocked in
        return {'success': false, 'message': 'You are already clocked in today'};
      }

      // Get current location 
      Position? position = await getCurrentLocation();
      
      Map<String, dynamic> attendanceData = {
        'userId': user.uid,
        'date': todayString,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'createdAt': FieldValue.serverTimestamp(), 
      };

      // Add location if available
      if (position != null) {
        attendanceData['startLocation'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }

      // Add timeout to Firestore operation
      await _firestore
          .collection('attendance')
          .add(attendanceData)
          .timeout(const Duration(seconds: 10));

      return {'success': true, 'message': 'Clocked in successfully!'};
    } catch (e) {
      print('Error clocking in: $e');
      return {'success': false, 'message': 'Error clocking in: ${e.toString()}'};
    }
  }

  // Clock out with better error handling and timeout
  Future<Map<String, dynamic>> clockOut() async {
    try {
      User? user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      DateTime now = DateTime.now();
      String todayString = DateFormat('yyyy-MM-dd').format(now);

      QuerySnapshot attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayString)
          .where('endTime', isEqualTo: null)
          .limit(1)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        return {'success': false, 'message': 'No active clock-in found'};
      }

      // Get current location (with timeout)
      Position? position = await getCurrentLocation();
      
      Map<String, dynamic> updateData = {
        'endTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), 
      };

      // Add location if available
      if (position != null) {
        updateData['endLocation'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }

      await _firestore
          .collection('attendance')
          .doc(attendanceQuery.docs.first.id)
          .update(updateData)
          .timeout(const Duration(seconds: 10));

      return {'success': true, 'message': 'Clocked out successfully!'};
    } catch (e) {
      print('Error clocking out: $e');
      return {'success': false, 'message': 'Error clocking out: ${e.toString()}'};
    }
  }

  // Get attendance history with better error handling
  Future<List<Map<String, dynamic>>> getAttendanceHistory({int limit = 10}) async {
    try {
      User? user = currentUser;
      if (user == null) return [];

      QuerySnapshot attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return attendanceQuery.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'date': data['date'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'startLocation': data['startLocation'],
          'endLocation': data['endLocation'],
        };
      }).toList();
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  // Sign out with error handling
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}