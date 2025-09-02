import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(title),
      backgroundColor:
          theme.colorScheme.primary, // uses primary color from theme
      iconTheme: IconThemeData(
        color: theme.colorScheme.onPrimary,
      ), // drawer icon color
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
