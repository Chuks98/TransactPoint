import 'package:flutter/material.dart';
import './confirm-dialog.dart'; // adjust path
import '../../services/user-api-services.dart'; // your logout function

class CustomSidebar extends StatelessWidget {
  CustomSidebar({super.key});

  final RegisterService _authService = RegisterService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Center(
              child: Text(
                "Welcome",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: theme.colorScheme.primary),
            title: Text("Home", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.savings, color: theme.colorScheme.primary),
            title: Text("Savings", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/savings');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.account_circle,
              color: theme.colorScheme.primary,
            ),
            title: Text("Profile", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.wallet, color: theme.colorScheme.primary),
            title: Text("Account", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/wallet');
            },
          ),
          ListTile(
            leading: Icon(Icons.support, color: theme.colorScheme.primary),
            title: Text("Support", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/support');
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
            title: Text("Privacy Policy", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/privacy');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            title: Text("Settings", style: theme.textTheme.bodyMedium),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),

          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              "Logout",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => ConfirmDialog(
                      title: "Logout?",
                      content: const [
                        Text("Are you sure you want to log out?"),
                      ],
                      confirmText: "Logout",
                      cancelText: "Cancel",
                      onConfirm: () {
                        Navigator.of(ctx).pop(); // close dialog
                        _authService.logout(context);
                      },
                      onCancel: () => Navigator.of(ctx).pop(),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
