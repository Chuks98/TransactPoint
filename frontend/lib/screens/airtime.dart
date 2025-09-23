import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import '../../services/flutterwave-api-services.dart';
import './custom-widgets/airtime-widgets.dart';
import '../../services/user-api-services.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final ApiService _billService = ApiService();
  final RegisterService _registerService = RegisterService();

  Map<String, List<dynamic>> _airtimeBillers = {};
  String? _selectedBillerCode; // <-- track selected biller
  String? _selectedItemCode;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();

  int? _selectedTopUpAmount;
  bool _isLoading = false;

  final List<Map<String, dynamic>> topUpOptions = [
    {'amount': 50, 'cashback': 0.5},
    {'amount': 100, 'cashback': 1},
    {'amount': 200, 'cashback': 2},
    {'amount': 500, 'cashback': 5},
    {'amount': 1000, 'cashback': 10},
    {'amount': 2000, 'cashback': 20},
  ];

  @override
  void initState() {
    super.initState();
    _registerService.loadUserData().then((_) {
      setState(() {}); // refresh UI after load
    });
    _loadAirtimeBills();
  }

  Future<void> _loadAirtimeBills() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("This is the user id: ${RegisterService.userId.toString()}");
    });
    try {
      final _airtimeBills = await _billService.fetchBillersByCategory(
        'airtime',
      );

      final Map<String, dynamic> mappedBillers = {};
      for (var biller in _airtimeBills.values.expand((list) => list)) {
        final name = (biller['name'] ?? "").toUpperCase();
        for (var key in billerLogos.keys) {
          if (name.contains(key)) {
            mappedBillers.putIfAbsent(key, () => biller);
          }
        }
      }

      setState(() {
        _airtimeBillers = _airtimeBills;

        // Auto-select MTN if it exists
        if (_airtimeBillers.containsKey("MTN")) {
          final mtnBiller = _airtimeBillers["MTN"]!.first;
          _selectedBillerCode =
              mtnBiller['biller_code']; // ✅ This is the biller code
          _selectedItemCode = mtnBiller['item_code'];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
      showCustomSnackBar(context, "Failed to load billers");
    }
  }

  void _onTopUpSelected(int amount) {
    setState(() {
      _selectedTopUpAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _purchaseAirtime() async {
    final phone = _phoneController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (_selectedBillerCode == null) {
      showCustomSnackBar(context, "Please select a network");
      return;
    }

    if (phone.isEmpty || amount <= 0) {
      showCustomSnackBar(context, "Please enter valid phone and amount");
      return;
    }

    setState(() => _isLoading = true);

    await _apiService.purchaseAirtime(
      context: context,
      id: RegisterService.userId!,
      phone: phone,
      amount: amount,
      billerCode: _selectedBillerCode!,
      itemCode: _selectedItemCode!,
    );

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                promoBanner(),
                const SizedBox(height: 24),
                phoneNumberSection(
                  context,
                  controller: _phoneController,
                  airtimeBillers:
                      _airtimeBillers.values.expand((list) => list).toList(),
                  selectedBillerCode: _selectedBillerCode,
                  onBillerChanged: (selectedCode) {
                    setState(() {
                      _selectedBillerCode = selectedCode;

                      // Find biller by code
                      final allBillers =
                          _airtimeBillers.values
                              .expand((list) => list)
                              .toList();
                      final selectedBiller = allBillers.firstWhere(
                        (b) => b['biller_code'] == selectedCode,
                      );
                      _selectedItemCode = selectedBiller['item_code'];
                    });
                  },
                ),

                const SizedBox(height: 24),
                ussdBanner(context),
                const SizedBox(height: 24),
                topUpSection(
                  context,
                  topUpOptions,
                  _selectedTopUpAmount,
                  _onTopUpSelected,
                ),
                const SizedBox(height: 24),
                customAmountSection(
                  context,
                  _amountController,
                  () => setState(() => _selectedTopUpAmount = null),
                  _purchaseAirtime,
                ),

                const SizedBox(height: 24),
                airtimeServiceSection(context),
                const SizedBox(height: 24),
              ],
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
