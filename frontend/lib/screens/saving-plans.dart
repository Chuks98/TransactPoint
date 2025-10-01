import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/saving-plan.dart';
import '../services/user-api-services.dart';
import 'saving-plan-details.dart';
import 'custom-widgets/snackbar.dart';

class SavingsPlansScreen extends StatefulWidget {
  const SavingsPlansScreen({super.key});

  @override
  State<SavingsPlansScreen> createState() => _SavingsPlansScreenState();
}

class _SavingsPlansScreenState extends State<SavingsPlansScreen> {
  late Future<List<Plan>> _plansFuture;
  final RegisterService api = RegisterService();
  final storage = const FlutterSecureStorage();

  String? userId;
  String? currency;

  @override
  void initState() {
    super.initState();
    _plansFuture = api.getPlans(context);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? userJson = await storage.read(key: "logged_in_user");
      if (userJson == null) return;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>? ?? {};
      userId = userMap['id']?.toString();

      if (userId != null) {
        final walletRes = await api.getWallet(userId!);
        if (walletRes['status'] == 'success' && walletRes['data'] != null) {
          final walletData = walletRes['data'];
          setState(() {
            currency = walletData['currency'];
          });
        }
      }
    } catch (e) {
      print("🚨 _loadUserData error: $e");
    }
  }

  Future<void> _refreshPlans() async {
    setState(() {
      _plansFuture = api.getPlans(context);
    });
    await _plansFuture;
  }

  void _openPlan(Plan plan) {
    if (currency != "NGN") {
      showCustomSnackBar(
        context,
        "Only NGN account can start a saving plan. Go to accounts and change your currency to NGN",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailsScreen(plan: plan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              return RefreshIndicator(
                onRefresh: _refreshPlans,
                child: ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('No plans available')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refreshPlans,
              child: ListView.builder(
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
                      onTap: () => _openPlan(p),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
