import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  SessionManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _timer;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(minutes: 7),
      _logoutUser,
    ); // 2 minutes timeout
  }

  Future<void> _logoutUser() async {
    await _storage.delete(key: 'is_logged_in');
    debugPrint("⏰ Session expired: is_logged_in deleted");
  }

  // Call this whenever user interacts with the app
  void userActivity() => _resetTimer();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background/sleep
      _timer?.cancel();
      _timer = Timer(const Duration(minutes: 7), _logoutUser);
    } else if (state == AppLifecycleState.resumed) {
      // Restart timer when app comes back
      _resetTimer();
    }
  }
}
