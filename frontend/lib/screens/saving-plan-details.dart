import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/number-formatter.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:transact_point/theme.dart';
import '../models/saving-plan.dart';
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
  String? currencySign;
  String? userBalance;
  String? userId;
  DateTime? startDate;
  DateTime? _maturityDate;
  final storage = const FlutterSecureStorage();
  final RegisterService api = RegisterService();
  final NumberFormat currencyFormatter = NumberFormat("#,##0.00", "en_US");

  String _formatBalance(String balance) {
    try {
      final value = double.tryParse(balance) ?? 0.0;
      return currencyFormatter.format(value);
    } catch (e) {
      print("Balance formatting failed: $e");
      return balance;
    }
  }

  double _calculateMaturity(double principal, Plan plan) {
    if (!plan.withInterest ||
        plan.interestRate <= 0 ||
        plan.durationMonths <= 0) {
      return principal;
    }

    final r = plan.interestRate / 100; // interest rate for the plan duration

    if (plan.interestType.toLowerCase() == 'compound') {
      // Compound interest per month
      return principal * pow(1 + r, plan.durationMonths);
    } else {
      // Simple interest per month
      return principal + (principal * r * plan.durationMonths);
    }
  }

  void _updatePreview() {
    final entered = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (entered <= 0) {
      setState(() {
        _maturity = null;
        _interestEarned = null;
        _maturityDate = null;
      });
      return;
    }
    final m = _calculateMaturity(entered, widget.plan);

    // Calculate maturity date
    startDate = DateTime.now();
    DateTime maturityDate = startDate!.add(
      Duration(
        days: (widget.plan.durationMonths * 30), // approximate month as 30 days
      ),
    );

    setState(() {
      _maturity = m;
      _interestEarned = m - entered;
      _maturityDate = maturityDate;
    });
  }

  Future<void> _fetchWallet() async {
    String? userJson = await storage.read(key: "logged_in_user");
    if (userJson == null) return;

    final userMap = jsonDecode(userJson) as Map<String, dynamic>? ?? {};

    userId = userMap['id']?.toString();
    final walletRes = await api.getWallet(userId!);
    if (walletRes['status'] == 'success' && walletRes['data'] != null) {
      final walletData = walletRes['data'];
      setState(() {
        userBalance = walletData['balance'].toString();
        currencySign = walletData['currencySign'];
      });

      // Block savings if wallet is not NGN
      if (walletData['currency'] != 'NGN') {
        showCustomSnackBar(context, "Savings available only in NGN wallets");
        Navigator.pop(context);
      }
    }
  }

  Future<void> _startSaving() async {
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    print(amt);
    final balance = double.tryParse(userBalance ?? '0') ?? 0;

    if (balance < amt) {
      showCustomSnackBar(context, 'Insufficient account balance');
      return;
    }
    if (amt <= 0) {
      showCustomSnackBar(context, 'Enter a valid amount');
      return;
    }
    if (amt < widget.plan.minAmount) {
      showCustomSnackBar(context, 'Minimum is ₦${widget.plan.minAmount}');
      return;
    }
    if (widget.plan.maxAmount != null && amt > widget.plan.maxAmount!) {
      showCustomSnackBar(context, 'Maximum is ₦${widget.plan.maxAmount!}');
      return;
    }

    // Show confirmation popup
    final confirmed = await _showSavingConfirmationDialog();
    if (confirmed != true) return; // User cancelled

    setState(() => _loading = true);

    DateTime startDate = DateTime.now();
    DateTime endDate = startDate.add(
      Duration(days: widget.plan.durationMonths * 30),
    );

    bool created = await api.createSaving(
      context,
      userId: userId!,
      planId: widget.plan.id,
      principal: amt,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
    );

    setState(() => _loading = false);
    if (created) Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();

    _amountCtrl.addListener(() {
      final text = _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      if (text.isEmpty) {
        _updatePreview(); // reset preview if empty
        return;
      }

      final value = double.tryParse(text) ?? 0;

      // Format the text with CurrencyFormatter
      final formatted = CurrencyFormatter.format(value, withSymbol: false);

      // Only update if different to avoid cursor jump
      if (_amountCtrl.text != formatted) {
        _amountCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }

      _updatePreview();
    });

    _fetchWallet(); // fetch wallet on page load
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan details card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.percent),
                      title: Text(
                        p.withInterest
                            ? '${p.interestRate}% (${p.interestType})'
                            : 'No interest',
                      ),
                      subtitle: const Text("Interest Rate"),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        p.durationMonths > 0
                            ? '${p.durationMonths} months'
                            : 'Flexible',
                      ),
                      subtitle: const Text("Duration"),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text("₦", style: TextStyle(fontSize: 26)),
                      title: Text(
                        "Min: ${CurrencyFormatter.format(p.minAmount.toDouble(), withSymbol: true)}"
                        "${p.maxAmount != null ? ' • Max: ${CurrencyFormatter.format(p.maxAmount!.toDouble(), withSymbol: true)}' : ''}",
                      ),
                      subtitle: const Text("Amount Range"),
                    ),
                    if (userBalance != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.account_balance_wallet),
                        title: Text(
                          "Balance: ₦${_formatBalance(userBalance!)}",
                        ),
                        subtitle: const Text("Your Account"),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input field
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Enter amount to save',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "₦",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Preview card
            if (_maturity != null)
              Card(
                color: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Interest Earned: ₦${_interestEarned!.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Maturity Amount: ${CurrencyFormatter.format(_maturity!)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      if (_maturityDate != null)
                        Text(
                          "Maturity Date: ${DateFormat.yMMMEd().format(_maturityDate!)}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startSaving,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

  Future<bool?> _showSavingConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    "Confirm Your Saving",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details
                  _buildDetailRow("Plan", widget.plan.name),
                  _buildDetailRow(
                    "Amount",
                    CurrencyFormatter.format(
                      double.tryParse(_amountCtrl.text.replaceAll(',', '')) ??
                          0,
                    ),
                  ),
                  if (_interestEarned != null)
                    _buildDetailRow(
                      "Interest",
                      "₦${_interestEarned!.toStringAsFixed(2)}",
                    ),
                  if (_maturity != null)
                    _buildDetailRow(
                      "Maturity Amount",
                      "₦${CurrencyFormatter.format(_maturity!, withSymbol: false)}",
                    ),
                  if (_maturityDate != null)
                    _buildDetailRow(
                      "Maturity Date",
                      DateFormat.yMMMEd().format(_maturityDate!),
                    ),
                  const SizedBox(height: 20),

                  const Text(
                    "Are you sure you want to proceed?",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Helper widget for each row in dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
