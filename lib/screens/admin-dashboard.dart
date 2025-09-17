import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/services/admin-api-services.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: 100 * index), // staggered animation
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(.15),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AdminService _adminService = AdminService();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildDashboardCard(
            context: context,
            icon: Icons.people,
            title: "Manage Users",
            subtitle: "View and manage all registered users",
            onTap: () {
              Navigator.pushNamed(context, "/admin-users");
            },
            index: 1,
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.account_balance_wallet,
            title: "Manage Wallets",
            subtitle: "View and manage user wallets",
            onTap: () {
              Navigator.pushNamed(context, "/admin-wallets");
            },
            index: 2,
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.swap_horiz,
            title: "Transactions",
            subtitle: "View all transactions in the system",
            onTap: () {
              Navigator.pushNamed(context, "/admin-transactions");
            },
            index: 3,
          ),
          _buildDashboardCard(
            context: context,
            icon: Icons.pending_actions,
            title: "Pending Transactions",
            subtitle: "Check transactions awaiting approval",
            onTap: () {
              Navigator.pushNamed(context, "/admin-transactions-pending");
            },
            index: 4,
          ),
        ],
      ),
    );
  }
}
