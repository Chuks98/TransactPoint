import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
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
  late Future<List<UserSaving>> _future;

  @override
  void initState() {
    super.initState();
    _future = api.getUserSavings(context, 1);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = api.getUserSavings(context, 1);
    });
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
  }

  Widget _buildCard(UserSaving s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(s.planName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved: ${s.principal.toStringAsFixed(2)}'),
            Text('Maturity: ${s.maturityAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: s.progress()),
            const SizedBox(height: 6),
            Text('Ends: ${s.endDate.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!s.withdrawn)
              ElevatedButton(
                onPressed: () => _attemptWithdraw(s),
                child: Text(s.matured ? 'Withdraw' : 'Early withdraw'),
              )
            else
              const Text('Withdrawn'),
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
        child: FutureBuilder<List<UserSaving>>(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SavingsPlansScreen(),
                                  ),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavingsPlansScreen()),
          ).then((value) => _refresh());
        },
        label: const Text("New Saving"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
