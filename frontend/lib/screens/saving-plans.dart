import 'package:flutter/material.dart';
import '../models/saving-plan.dart';
import '../services/user-api-services.dart';
import 'saving-plan-details.dart';

class SavingsPlansScreen extends StatefulWidget {
  const SavingsPlansScreen({super.key});

  @override
  State<SavingsPlansScreen> createState() => _SavingsPlansScreenState();
}

class _SavingsPlansScreenState extends State<SavingsPlansScreen> {
  late Future<List<Plan>> _plansFuture;
  final RegisterService api = RegisterService();

  @override
  void initState() {
    super.initState();
    _plansFuture = api.getPlans(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Plans')),
      body: FutureBuilder<List<Plan>>(
        future: _plansFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          } else {
            final plans = snap.data ?? [];
            if (plans.isEmpty) {
              return const Center(child: Text('No plans available'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final p = plans[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    title: Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      p.withInterest
                          ? '${p.interestRate}% ${p.interestType} • ${p.durationMonths > 0 ? '${p.durationMonths} months' : 'Flexible'}'
                          : 'No interest • ${p.durationMonths > 0 ? '${p.durationMonths} months' : 'Flexible'}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanDetailsScreen(plan: p),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
