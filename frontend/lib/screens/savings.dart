import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transact_point/screens/saving-plans.dart';
import '../models/user-savings.dart';
import '../services/user-api-services.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final RegisterService api = RegisterService();
  final storage = const FlutterSecureStorage();
  Future<List<UserSaving>>? _future;
  String? userId; // hold logged-in user id

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final userJson = await storage.read(key: 'logged_in_user');
    if (userJson == null) {
      setState(() {
        _future = Future.value([]);
      });
      return;
    }

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final parsedId = userMap['id']; // extract user id

      if (parsedId != null) {
        setState(() {
          userId = parsedId;
          _future = api.getUserSavings(context, parsedId);
        });
      }
    } catch (e) {
      print("❌ Error decoding logged_in_user: $e");
      setState(() {
        _future = Future.value([]);
      });
    }
  }

  Future<void> _refresh() async {
    if (userId != null) {
      setState(() {
        _future = api.getUserSavings(context, userId!);
      });
    }
  }

  Future<void> _attemptWithdraw(UserSaving s) async {
    if (!s.matured) {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Early Withdrawal'),
              content: const Text(
                'This saving has not matured. Withdrawing early may incur penalties. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
      );
      if (confirm != true) return;
    }

    await api.withdrawSaving(context, s.id);
    _refresh(); // refresh after withdrawal
  }

  Widget _buildCard(UserSaving s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.planName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Saved: ₦${s.principal.toStringAsFixed(2)}'),
            Text('Maturity: ₦${s.maturityAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: s.progress()),
            const SizedBox(height: 6),
            Text('Ends: ${s.endDate.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child:
                  s.withdrawn
                      ? const Text(
                        'Withdrawn',
                        style: TextStyle(color: Colors.grey),
                      )
                      : ElevatedButton(
                        onPressed: () => _attemptWithdraw(s),
                        child: Text(s.matured ? 'Withdraw' : 'Early withdraw'),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child:
            _future == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<UserSaving>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }

                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      // 👇 Empty state encourages starting a new saving
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.savings_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('You have no active savings'),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text("Start a Saving Plan"),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/saving-plans',
                                        ).then((value) => _refresh());
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _buildCard(list[i]),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/saving-plans',
          ).then((value) => _refresh());
        },
        label: const Text("New Saving"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
