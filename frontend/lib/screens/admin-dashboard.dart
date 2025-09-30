import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/screens/custom-widgets/curved-design.dart';
import 'package:transact_point/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isGridView = true; // default grid view

  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
  }) {
    final cardContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(.15),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: 100 * index),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                _isGridView
                    ? cardContent
                    : ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.15),
                        child: Icon(
                          icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dashboardItems = [
      {
        "icon": Icons.people,
        "title": "Manage Users",
        "subtitle": "View and manage all registered users",
        "route": "/admin-users",
      },
      {
        "icon": Icons.account_balance_wallet,
        "title": "Manage Wallets",
        "subtitle": "View and manage user wallets",
        "route": "/admin-wallets",
      },
      {
        "icon": Icons.swap_horiz,
        "title": "Transactions",
        "subtitle": "View all transactions in the system",
        "route": "/admin-transactions",
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header
          ClipPath(
            clipper: UCurveClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
<<<<<<< HEAD
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
=======
              color: AppColors.primary,
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
              alignment: Alignment.center,
              child: FadeInDown(
                child: Text(
                  "Welcome Admin",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Toggle buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    color: _isGridView ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isGridView = true),
                ),
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: !_isGridView ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),

          // Dashboard content
          Expanded(
            child:
                _isGridView
                    ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                          ),
                      itemCount: dashboardItems.length,
                      itemBuilder: (context, index) {
                        final item = dashboardItems[index];
                        return _buildDashboardCard(
                          context: context,
                          icon: item["icon"] as IconData,
                          title: item["title"] as String,
                          subtitle: item["subtitle"] as String,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                item["route"] as String,
                              ),
                          index: index,
                        );
                      },
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: dashboardItems.length,
                      itemBuilder: (context, index) {
                        final item = dashboardItems[index];
                        return _buildDashboardCard(
                          context: context,
                          icon: item["icon"] as IconData,
                          title: item["title"] as String,
                          subtitle: item["subtitle"] as String,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                item["route"] as String,
                              ),
                          index: index,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
