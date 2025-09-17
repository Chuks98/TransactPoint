import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AdminWalletsScreen extends StatelessWidget {
  const AdminWalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallets = [
      {"owner": "John Doe", "balance": 1200.50},
      {"owner": "Jane Smith", "balance": 350.75},
      {"owner": "Samuel Green", "balance": 5000.00},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return SlideInUp(
          delay: Duration(milliseconds: 120 * index),
          duration: const Duration(milliseconds: 450),
          child: Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(wallet['owner'] as String),
              subtitle: Text("Balance: ₦${wallet['balance']}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        );
      },
    );
  }
}
