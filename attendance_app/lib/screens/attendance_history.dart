// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_services.dart';
import '../utils/colors.dart';
import 'dart:ui';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _attendanceHistory = [];
  Map<String, dynamic>? _selectedDayAttendance;
  bool _isLoading = true;
  bool _isLoadingDayDetails = false;

  // Statistics
  int _totalWorkDays = 0;
  int _currentMonthDays = 0;
  String _averageWorkHours = "0h 0m";
  String _totalWorkHours = "0h 0m";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    _loadAttendanceHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> history =
          await _firebaseService.getAttendanceHistory(limit: 50);

      setState(() {
        _attendanceHistory = history;
        _calculateStatistics();
        _isLoading = false;
      });

      // Load today's details if available
      if (_selectedDay != null) {
        _loadSelectedDayDetails(_selectedDay!);
      }
    } catch (e) {
      print('Error loading attendance history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedDayDetails(DateTime day) async {
    setState(() {
      _isLoadingDayDetails = true;
    });

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(day);

      // Find attendance for the selected day
      Map<String, dynamic>? dayAttendance = _attendanceHistory.firstWhere(
        (attendance) => attendance['date'] == dateString,
        orElse: () => {},
      );

      setState(() {
        _selectedDayAttendance =
            dayAttendance.isNotEmpty ? dayAttendance : null;
        _isLoadingDayDetails = false;
      });
    } catch (e) {
      print('Error loading selected day details: $e');
      setState(() {
        _isLoadingDayDetails = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalWorkDays = _attendanceHistory.length;

    // Calculate current month days
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    _currentMonthDays = _attendanceHistory.where((attendance) {
      DateTime attendanceDate =
          DateFormat('yyyy-MM-dd').parse(attendance['date']);
      return attendanceDate
              .isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
          attendanceDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    }).length;

    // Calculate total and average work hours
    int totalMinutes = 0;
    int completedDays = 0;

    for (var attendance in _attendanceHistory) {
      if (attendance['startTime'] != null && attendance['endTime'] != null) {
        DateTime startTime = attendance['startTime'].toDate();
        DateTime endTime = attendance['endTime'].toDate();

        Duration workDuration = endTime.difference(startTime);
        totalMinutes += workDuration.inMinutes;
        completedDays++;
      }
    }

    if (completedDays > 0) {
      int totalHours = totalMinutes ~/ 60;
      int remainingMinutes = totalMinutes % 60;
      _totalWorkHours = '${totalHours}h ${remainingMinutes}m';

      int averageMinutes = totalMinutes ~/ completedDays;
      int avgHours = averageMinutes ~/ 60;
      int avgRemainingMinutes = averageMinutes % 60;
      _averageWorkHours = '${avgHours}h ${avgRemainingMinutes}m';
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
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarView(),
                    _buildHistoryListView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkBlue),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                Text(
                  'View your work schedule and statistics',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
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
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.darkGray,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.calendar_month),
            text: 'Calendar',
          ),
          Tab(
            icon: Icon(Icons.list),
            text: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 20),
          _buildSelectedDayDetails(),
        ],
      ),
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendar() {
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    int daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    int firstWeekday = firstDayOfMonth.weekday;
    List<Widget> dayWidgets = [];

    // Add blank widgets for previous month's trailing days
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDay = DateTime(_focusedDay.year, _focusedDay.month, day);
      bool isSelected = isSameDay(_selectedDay, currentDay);
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDay);
      bool hasAttendance = _attendanceHistory.any((a) => a['date'] == dateStr);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDay;
              _focusedDay = currentDay;
            });
            _loadSelectedDayDetails(currentDay);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : hasAttendance
                      ? AppColors.successGreen.withOpacity(0.2)
                      : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? AppColors.primaryColor : AppColors.mediumGray,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isSelected
                    ? AppColors.white
                    : hasAttendance
                        ? AppColors.successGreen
                        : AppColors.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  );
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          shrinkWrap: true,
          children: dayWidgets,
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetails() {
    if (_selectedDay == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.event, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Text(
                      'Attendance Details',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGray.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingDayDetails)
            const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          else if (_selectedDayAttendance != null)
            _buildDayAttendanceCard(_selectedDayAttendance!)
          else
            _buildNoAttendanceCard(),
        ],
      ),
    );
  }

  Widget _buildDayAttendanceCard(Map<String, dynamic> attendance) {
    DateTime? startTime = attendance['startTime']?.toDate();
    DateTime? endTime = attendance['endTime']?.toDate();

    String workDuration = '';
    if (startTime != null && endTime != null) {
      Duration duration = endTime.difference(startTime);
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);
      workDuration = '${hours}h ${minutes}m';
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Work Day Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeDetailCard(
                  'Clock In',
                  startTime != null
                      ? DateFormat('HH:mm').format(startTime)
                      : '--:--',
                  Icons.login,
                  AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDetailCard(
                  'Clock Out',
                  endTime != null
                      ? DateFormat('HH:mm').format(endTime)
                      : '--:--',
                  Icons.logout,
                  AppColors.errorRed,
                ),
              ),
            ],
          ),
          if (workDuration.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
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
                    Icons.timer,
                    color: AppColors.darkBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Work Time: $workDuration',
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

  Widget _buildTimeDetailCard(
      String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
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
      ),
    );
  }

  Widget _buildNoAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mediumGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mediumGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkGray.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_busy,
              color: AppColors.darkGray,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Attendance Record',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  'No work activity recorded for this day',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (_attendanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history,
                size: 64,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Attendance History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start clocking in to see your attendance history',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _attendanceHistory.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_attendanceHistory[index]);
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> attendance) {
    DateTime date = DateFormat('yyyy-MM-dd').parse(attendance['date']);
    DateTime? startTime = attendance['startTime']?.toDate();
    DateTime? endTime = attendance['endTime']?.toDate();

    bool isCompleted = endTime != null;
    String workDuration = '';

    if (startTime != null && endTime != null) {
      Duration duration = endTime.difference(startTime);
      int hours = duration.inHours;
      int minutes = duration.inMinutes.remainder(60);
      workDuration = '${hours}h ${minutes}m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isCompleted
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isCompleted
                                ? AppColors.successGreen
                                : AppColors.warningOrange)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.access_time,
                        color: isCompleted
                            ? AppColors.successGreen
                            : AppColors.warningOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          Text(
                            isCompleted ? 'Completed' : 'In Progress',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted
                                  ? AppColors.successGreen
                                  : AppColors.warningOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (workDuration.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workDuration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        'Clock In',
                        startTime != null
                            ? DateFormat('HH:mm').format(startTime)
                            : '--:--',
                        Icons.login,
                        AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeInfo(
                        'Clock Out',
                        endTime != null
                            ? DateFormat('HH:mm').format(endTime)
                            : '--:--',
                        Icons.logout,
                        AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
