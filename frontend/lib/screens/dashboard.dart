import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, size: 40),
              title: Text(
                "Total Balance",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                "\$12,450.00",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              // trailing: FittedBox(
              //   child: ElevatedButton(
              //     onPressed: () {},
              //     child: const Text("Top Up"),
              //   ),
              // ),
            ),
          ),
          const SizedBox(height: 20),

          // Recent Transactions Title
          Text(
            "Recent Transactions",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),

          // Recent Transactions List
          ListView.builder(
            shrinkWrap: true, // important: size list to content
            physics:
                const NeverScrollableScrollPhysics(), // avoid nested scroll
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                leading: Icon(
                  tx['type'] == 'income'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: tx['type'] == 'income' ? Colors.green : Colors.red,
                ),
                title: Text(tx['title']!),
                subtitle: Text(tx['date']!),
                trailing: Text(tx['amount']!),
              );
            },
          ),
        ],
      ),
    );
  }

  // Sample transactions (you can move this to a model later)
  final List<Map<String, String>> transactions = const [
    {
      'title': 'Payment to Netflix',
      'date': 'Jan 20, 2025',
      'amount': '- \$15.00',
      'type': 'expense',
    },
    {
      'title': 'Salary',
      'date': 'Jan 18, 2025',
      'amount': '+ \$2,000.00',
      'type': 'income',
    },
    {
      'title': 'Grocery Shopping',
      'date': 'Jan 17, 2025',
      'amount': '- \$120.00',
      'type': 'expense',
    },
  ];
}
