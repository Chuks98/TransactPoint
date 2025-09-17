import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        "id": "#TX1001",
        "user": "John Doe",
        "amount": 200.00,
        "status": "Completed",
      },
      {
        "id": "#TX1002",
        "user": "Jane Smith",
        "amount": 500.00,
        "status": "Pending",
      },
      {
        "id": "#TX1003",
        "user": "Samuel Green",
        "amount": 150.00,
        "status": "Failed",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        Color statusColor;
        switch (tx['status']) {
          case "Completed":
            statusColor = Colors.green;
            break;
          case "Pending":
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.red;
        }

        return ZoomIn(
          delay: Duration(milliseconds: 100 * index),
          duration: const Duration(milliseconds: 400),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(Icons.receipt_long, color: statusColor),
              ),
              title: Text("${tx['id']} - ${tx['user']}"),
              subtitle: Text("₦${tx['amount']} • ${tx['status']}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        );
      },
    );
  }
}
