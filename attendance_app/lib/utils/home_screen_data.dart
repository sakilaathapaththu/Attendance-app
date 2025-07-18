class HomeScreenData {
  final String userName;
  final bool isStarted;
  final bool isCompleted;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool hasError;
  final String? errorMessage;

  HomeScreenData({
    required this.userName,
    required this.isStarted,
    required this.isCompleted,
    required this.startTime,
    required this.endTime,
    required this.hasError,
    required this.errorMessage,
  });
}