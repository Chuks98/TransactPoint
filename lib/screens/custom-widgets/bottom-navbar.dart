import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // 👈 avoid double shadow
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: "Airtime",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.swap_horiz), // transfer-like icon
            label: "Transfers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        selectedItemColor:
            theme.bottomNavigationBarTheme.selectedItemColor ??
            theme.primaryColor,
        unselectedItemColor:
            theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey,
        backgroundColor:
            theme.bottomNavigationBarTheme.backgroundColor ??
            theme.scaffoldBackgroundColor,
      ),
    );
  }
}
