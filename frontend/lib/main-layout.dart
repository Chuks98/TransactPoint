import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './screens/custom-widgets/appbar.dart';
import './screens/custom-widgets/sidebar.dart';
import './screens/custom-widgets/bottom-navbar.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final int initialIndex; // 👈 add this

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.initialIndex = 0, // default Home
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  final List<String> _routes = [
    '/home',
    '/airtime',
    '/transfer',
    '/profile',
    '/settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // secure storage (or auth service) check
    final isLoggedIn = await const FlutterSecureStorage().read(
      key: 'is_logged_in',
    );

    if (isLoggedIn != 'true') {
      // user not logged in → go to login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: widget.showBackButton,
      ),
      drawer: CustomSidebar(),
      body: widget.body,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          Navigator.pushReplacementNamed(context, _routes[index]);
        },
      ),
    );
  }
}
