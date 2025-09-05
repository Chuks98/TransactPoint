import 'package:flutter/material.dart';
import './screens/custom-widgets/appbar.dart';
import './screens/custom-widgets/sidebar.dart';
import './screens/custom-widgets/bottom-navbar.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showBackButton;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<String> _routes = ['/home', '/dashboard', '/profile', '/settings'];

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
          setState(() {
            _currentIndex = index;
          });
          // navigate to corresponding route
          Navigator.pushReplacementNamed(context, _routes[index]);
        },
      ),
    );
  }
}
