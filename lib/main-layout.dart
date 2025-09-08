import 'package:flutter/material.dart';
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
    _currentIndex = widget.initialIndex; // 👈 start from correct tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: widget.showBackButton,
      ),
      drawer: const CustomSidebar(),
      body: widget.body,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return; // avoid reloading same tab
          Navigator.pushReplacementNamed(context, _routes[index]);
        },
      ),
    );
  }
}
