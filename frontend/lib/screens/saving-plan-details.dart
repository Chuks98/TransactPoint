// lib/screens/plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'dart:math';
import '../models/saving-plan.dart';
import '../models/user-savings.dart';
import '../services/user-api-services.dart';

class PlanDetailsScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailsScreen({required this.plan, super.key});

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  double? _maturity;
  double? _interestEarned;
  bool _loading = false;
  final RegisterService api = RegisterService();

  double _calculateMaturity(double principal, Plan plan) {
    if (!plan.withInterest ||
        plan.interestRate <= 0 ||
        plan.durationMonths <= 0) {
      return principal;
    }

    final r = plan.interestRate / 100; // e.g. 0.10
    final t = plan.durationMonths / 12.0; // years

    if (plan.interestType.toLowerCase() == 'compound') {
      // For compound, assume yearly compounding. If you want monthly compounding adjust accordingly.
      final amount = principal * (pow(1 + r, t));
      return amount;
    } else {
      // simple
      final interest = principal * r * t;
      return principal + interest;
    }
  }

  void _updatePreview() {
    final entered = double.tryParse(_amountCtrl.text) ?? 0;
    if (entered <= 0) {
      setState(() {
        _maturity = null;
        _interestEarned = null;
      });
      return;
    }
    final m = _calculateMaturity(entered, widget.plan);
    setState(() {
      _maturity = m;
      _interestEarned = m - entered;
    });
  }

  Future<void> _startSaving() async {
    final amt = double.tryParse(_amountCtrl.text) ?? 0;
    if (amt <= 0) {
      showCustomSnackBar(context, 'Enter a valid amount');
      return;
    }
    if (amt < widget.plan.minAmount) {
      showCustomSnackBar(context, 'Minimum is ${widget.plan.minAmount}');
      return;
    }
    if (widget.plan.maxAmount != null && amt > widget.plan.maxAmount!) {
      showCustomSnackBar(context, 'Maximum is ${widget.plan.maxAmount}');
      return;
    }

    setState(() => _loading = true);

    bool created = await api.createSaving(
      context,
      userId: 1,
      planId: widget.plan.id,
      amount: amt,
    );

    setState(() => _loading = false);

    Navigator.pop(context, created);
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.description),
            const SizedBox(height: 12),
            Text(
              'Interest: ${p.withInterest ? '${p.interestRate}% (${p.interestType})' : 'No interest'}',
            ),
            Text(
              'Duration: ${p.durationMonths > 0 ? '${p.durationMonths} months' : 'Flexible'}',
            ),
            Text(
              'Min: ${p.minAmount} ${p.maxAmount != null ? ' • Max: ${p.maxAmount}' : ''}',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Enter amount to save',
              ),
            ),
            const SizedBox(height: 12),
            if (_maturity != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interest Earned: ${_interestEarned!.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Maturity Amount: ${_maturity!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startSaving,
                child:
                    _loading
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Start Saving'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
