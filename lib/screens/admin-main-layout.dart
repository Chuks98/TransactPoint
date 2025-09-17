import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/services/admin-api-services.dart';

/// Admin Main Layout
class AdminMainLayout extends StatefulWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final int initialIndex;

  const AdminMainLayout({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.initialIndex = 0,
  });

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  late int _currentIndex;
  final AdminService _adminService = AdminService();

  final List<String> _routes = [
    '/admin-dashboard',
    '/admin-users',
    '/admin-wallets',
    '/admin-transactions',
    '/admin-settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await const FlutterSecureStorage().read(
      key: 'is_logged_in',
    );

    if (isLoggedIn == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin-login',
          (route) => false,
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              "Admin Panel",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () => Navigator.pushNamed(context, '/admin-dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Users"),
            onTap: () => Navigator.pushNamed(context, '/admin-users'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text("Wallets"),
            onTap: () => Navigator.pushNamed(context, '/admin-wallets'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text("Transactions"),
            onTap: () => Navigator.pushNamed(context, '/admin-transactions'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => _adminService.logoutAdmin(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.secondary,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (_currentIndex == index) return;
        Navigator.pushReplacementNamed(context, _routes[index]);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: "Wallets",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz),
          label: "Transactions",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 400),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading:
              widget.showBackButton
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )
                  : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _adminService.logoutAdmin(context),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: widget.body,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}
