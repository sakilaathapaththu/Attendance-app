import 'package:attendance_app/screens/home_screen.dart';
import 'package:attendance_app/services/firebase_services.dart';
import 'package:attendance_app/utils/home_screen_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _initializeAppData();
  }

  void _initializeAppData() async {
    try {
      // Wait for minimum splash duration for better UX
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        User? user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          // User is logged in, load their data
          await _loadUserData();
        } else {
          // User is not logged in, navigate to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        }
      }
    } catch (e) {
      print('Error initializing app data: $e');
      // Even if there's an error, continue to home screen
      // The home screen can handle errors gracefully
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              preloadedData: HomeScreenData(
                userName: 'User',
                isStarted: false,
                isCompleted: false,
                startTime: null,
                endTime: null,
                hasError: true,
                errorMessage: 'Failed to load data: ${e.toString()}',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data and attendance status in parallel
      String userName = await _firebaseService.loadUserData();
      Map<String, dynamic> attendanceResult = await _firebaseService.checkTodayAttendance();
      
      if (mounted) {
        // Navigate to home screen with preloaded data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              preloadedData: HomeScreenData(
                userName: userName,
                isStarted: attendanceResult['isStarted'] ?? false,
                isCompleted: attendanceResult['isCompleted'] ?? false,
                startTime: attendanceResult['startTime'],
                endTime: attendanceResult['endTime'],
                hasError: false,
                errorMessage: null,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              preloadedData: HomeScreenData(
                userName: 'User',
                isStarted: false,
                isCompleted: false,
                startTime: null,
                endTime: null,
                hasError: true,
                errorMessage: 'Failed to load data: ${e.toString()}',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 60,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Attendance Pro',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Track your time, boost productivity',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Loading indicator
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your data...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
