import 'package:flutter/material.dart';
import 'package:transact_point/screens/admin-savings-plans-form.dart';
import 'package:transact_point/services/admin-api-services.dart';
import '../models/saving-plan.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  final AdminService api = AdminService();
  late Future<List<Plan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _plansFuture = api.getPlans(context);
    });
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Plan"),
            content: const Text("Are you sure you want to delete this plan?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final ok = await api.deletePlan(context, id);
      if (ok) _refresh();
    }
  }

  void _openPlanForm({Plan? plan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: AdminSavingsPlanForm(
              existing: plan,
              onSaved: (ok) {
                Navigator.pop(ctx);
                if (ok) _refresh();
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Savings Plans")),
      body: Column(
        children: [
          // Curved header
          ClipPath(
            clipper: UCurveClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
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
              alignment: Alignment.center,
              child: Text(
                "Manage Saving Plans",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Content (plans list)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refresh();
                await _plansFuture;
              },
              child: FutureBuilder<List<Plan>>(
                future: _plansFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    // Wrap loader in scrollable so refresh works
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }
                  if (snap.hasError) {
                    // Wrap error in scrollable so refresh works
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 300,
                          child: Center(child: Text("Error: ${snap.error}")),
                        ),
                      ],
                    );
                  }

                  final plans = snap.data ?? [];
                  if (plans.isEmpty) {
                    // Wrap "no data" in scrollable so refresh works
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(child: Text("No plans available")),
                        ),
                      ],
                    );
                  }

                  // Normal list
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: plans.length,
                    itemBuilder: (_, i) {
                      final p = plans[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            p.withInterest
                                ? "${p.interestRate}% ${p.interestType} • ${p.durationMonths > 0 ? '${p.durationMonths} months' : 'Flexible'}"
                                : "No interest • ${p.durationMonths > 0 ? '${p.durationMonths} months' : 'Flexible'}",
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == "edit") {
                                _openPlanForm(plan: p);
                              } else if (val == "delete") {
                                _deletePlan(p.id);
                              }
                            },
                            itemBuilder:
                                (ctx) => const [
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit"),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text("Delete"),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanForm(),
        label: const Text("New Plan"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
