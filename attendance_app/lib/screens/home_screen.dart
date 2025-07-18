import 'package:attendance_app/screens/attendance_history.dart';
import 'package:attendance_app/screens/auth/login_screen.dart';
import 'package:attendance_app/services/firebase_services.dart';
import 'package:attendance_app/utils/home_screen_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:async';
import '../../utils/colors.dart';

class HomeScreen extends StatefulWidget {
  final HomeScreenData? preloadedData;

  const HomeScreen({Key? key, this.preloadedData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isStarted = false;
  bool _isCompleted = false;
  DateTime? _lastStartTime;
  DateTime? _endTime;
  String _currentTime = '';
  String _userName = '';
  bool _isClockActionLoading = false;
  Timer? _timer;
  String _workingDuration = '';

  @override
  void initState() {
    super.initState();
    _initializeWithPreloadedData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Use Timer instead of recursive Future.delayed
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

          // Calculate working duration if user has started work
          if (_isStarted && _lastStartTime != null && !_isCompleted) {
            Duration workDuration = DateTime.now().difference(_lastStartTime!);

            if (workDuration.isNegative) {
              _lastStartTime = DateTime.now();
              workDuration = Duration.zero;
            }
            int hours = workDuration.inHours;
            int minutes = workDuration.inMinutes.remainder(60);
            int seconds = workDuration.inSeconds.remainder(60);
            _workingDuration =
                '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          } else {
            _workingDuration = '';
          }
        });
      }
    });
  }

  void _initializeWithPreloadedData() {
    if (widget.preloadedData != null) {
      final data = widget.preloadedData!;
      setState(() {
        _userName = data.userName;
        _isStarted = data.isStarted;
        _isCompleted = data.isCompleted;
        _lastStartTime = data.startTime;
        _endTime = data.endTime;
      });

      // Show error message if there was an error loading data
      if (data.hasError && data.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar(data.errorMessage!, AppColors.errorRed);
        });
      }
    } else {
      // Fallback: load data if no preloaded data
      _loadDataFallback();
    }
  }

  // Fallback method in case no preloaded data is provided
  Future<void> _loadDataFallback() async {
    try {
      await _loadUserData();
      await _checkTodayAttendance();
    } catch (e) {
      print('Error loading data: $e');
      _showSnackBar('Error loading data: ${e.toString()}', AppColors.errorRed);
    }
  }

  Future<void> _loadUserData() async {
    try {
      String userName = await _firebaseService.loadUserData();
      if (mounted) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkTodayAttendance() async {
    try {
      Map<String, dynamic> result =
          await _firebaseService.checkTodayAttendance();

      if (mounted) {
        setState(() {
          _isStarted = result['isStarted'] ?? false;
          _lastStartTime = result['startTime'];
          _endTime = result['endTime'];
          _isCompleted = result['isCompleted'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking attendance: $e');
      if (mounted) {
        _showSnackBar('Error checking attendance status', AppColors.errorRed);
      }
    }
  }

  Future<void> _clockIn() async {
    if (_isClockActionLoading) return;

    setState(() {
      _isClockActionLoading = true;
    });

    try {
      Map<String, dynamic> result = await _firebaseService.clockIn();

      if (mounted) {
        if (result['success']) {
          await _checkTodayAttendance();
          _showSnackBar(result['message'], AppColors.successGreen);
        } else {
          _showSnackBar(result['message'], AppColors.errorRed);
        }
      }
    } catch (e) {
      print('Error in clock in: $e');
      if (mounted) {
        _showSnackBar('Error clocking in: ${e.toString()}', AppColors.errorRed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClockActionLoading = false;
        });
      }
    }
  }

  Future<void> _clockOut() async {
    if (_isClockActionLoading) return;

    setState(() {
      _isClockActionLoading = true;
    });

    try {
      Map<String, dynamic> result = await _firebaseService.clockOut();

      if (mounted) {
        if (result['success']) {
          await _checkTodayAttendance();
          _showSnackBar(result['message'], AppColors.successGreen);
        } else {
          _showSnackBar(result['message'], AppColors.errorRed);
        }
      }
    } catch (e) {
      print('Error in clock out: $e');
      if (mounted) {
        _showSnackBar(
            'Error clocking out: ${e.toString()}', AppColors.errorRed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClockActionLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _firebaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      if (mounted) {
        _showSnackBar('Error logging out', AppColors.errorRed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightGray, AppColors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $_userName',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon:
                            const Icon(Icons.logout, color: AppColors.errorRed),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Time Display
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxWidth: double.infinity,
                    ),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 48,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentTime,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Time',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons.check_circle
                              : _isStarted
                                  ? Icons.work
                                  : Icons.work_off,
                          size: 48,
                          color: _isCompleted
                              ? AppColors.successGreen
                              : _isStarted
                                  ? AppColors.primaryColor
                                  : AppColors.darkGray,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _isCompleted
                                ? 'Work Completed Today!'
                                : _isStarted
                                    ? 'You are Working'
                                    : "You didn't start the work yet today",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isCompleted
                                  ? AppColors.successGreen
                                  : _isStarted
                                      ? AppColors.primaryColor
                                      : AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Working time counter
                        if (_isStarted &&
                            _lastStartTime != null &&
                            !_isCompleted) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.1),
                                  AppColors.primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.timer,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Working Time',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.darkGray,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _workingDuration,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                            fontFeatures: [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Started at ${DateFormat('HH:mm').format(_lastStartTime!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show start time for completed work
                        if (_isCompleted && _lastStartTime != null)
                          Text(
                            'Started at ${DateFormat('HH:mm').format(_lastStartTime!)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.darkGray,
                            ),
                          ),

                        // Completion badge
                        if (_isCompleted)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🎉 Great job today!',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Clock In/Out Button
                  if (!_isCompleted) _buildClockButton(),

                  if (!_isCompleted) const SizedBox(height: 24),

                  // Today's Summary
                  _buildTodaySummary(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          'View History',
                          Icons.history,
                          AppColors.accentTeal,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AttendanceHistoryScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom button widget with loading state
  Widget _buildClockButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _isStarted
            ? const LinearGradient(
                colors: [AppColors.errorRed, Color(0xFFE57373)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isStarted ? AppColors.errorRed : AppColors.primaryColor)
                .withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isClockActionLoading
              ? null
              : (_isStarted ? _clockOut : _clockIn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isClockActionLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    _isStarted ? Icons.logout : Icons.login,
                    color: Colors.white,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isClockActionLoading
                      ? (_isStarted ? 'Ending...' : 'Starting...')
                      : (_isStarted ? 'End' : 'Start'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              if (_isCompleted) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_isCompleted)
            _buildCompletedSummary()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Started',
                  _lastStartTime != null
                      ? DateFormat('HH:mm').format(_lastStartTime!)
                      : 'Pending',
                  Icons.login,
                  AppColors.successGreen,
                ),
                _buildSummaryItem(
                  'Ended',
                  _isStarted ? '--:--' : 'Pending',
                  Icons.logout,
                  AppColors.errorRed,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successGreen.withOpacity(0.1),
            AppColors.successGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.successGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Work Day Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for your dedication today',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeCard(
                'Start Time',
                _lastStartTime != null
                    ? DateFormat('HH:mm').format(_lastStartTime!)
                    : '--:--',
                Icons.play_arrow,
                AppColors.primaryColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.successGreen.withOpacity(0.3),
              ),
              _buildTimeCard(
                'End Time',
                _endTime != null
                    ? DateFormat('HH:mm').format(_endTime!)
                    : '--:--',
                Icons.stop,
                AppColors.errorRed,
              ),
            ],
          ),
          if (_lastStartTime != null && _endTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.darkGray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${_calculateWorkDuration()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard(String title, String time, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
      ],
    );
  }

  String _calculateWorkDuration() {
    if (_lastStartTime == null || _endTime == null) return '--:--';

    Duration duration = _endTime!.difference(_lastStartTime!);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
