import 'package:flutter/material.dart';

class CustomSidebar extends StatelessWidget {
  const CustomSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.background, // uses theme background
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary, // theme primary color
            ),
            child: Center(
              child: Text(
                "Welcome",
                style: theme.textTheme.titleLarge?.copyWith(
                  color:
                      theme
                          .colorScheme
                          .onPrimary, // automatically contrasts primary
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: theme.colorScheme.primary),
            title: Text("Home", style: theme.textTheme.bodyMedium),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.account_circle,
              color: theme.colorScheme.primary,
            ),
            title: Text("Profile", style: theme.textTheme.bodyMedium),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            title: Text("Settings", style: theme.textTheme.bodyMedium),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            title: Text("Register", style: theme.textTheme.bodyMedium),
            onTap: () {
              // Navigator.pushReplacementNamed(context, '/register');
              Navigator.pushNamed(context, '/register');
            },
          ),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              "Logout",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.redAccent,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
