import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? showBackButton;

  const CustomAppBar({super.key, required this.title, this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(title),
      backgroundColor: theme.colorScheme.primary,
      iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      // If showBackButton is true, force back arrow. Otherwise, let Scaffold handle drawer icon.
      leading:
          showBackButton!
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          color: theme.colorScheme.onPrimary,
          onPressed: () {
            Navigator.pushNamed(context, '/wallet');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
