import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import 'package:transact_point/services/user-api-services.dart';
import './custom-widgets/electricity-widgets.dart'; // You can rename or create electricity-widgets.dart

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final ApiService _billService = ApiService();
  final RegisterService _registerService = RegisterService();
  String? _selectedProvider; // E.g., IKEDC, EEDC, KEDCO
  bool _isLoading = true;
  final TextEditingController _meterController = TextEditingController();

  String? _selectedAmount;
  String? _selectedBillerCode;
  String? _selectedItemCode;
  List<Map<String, dynamic>> _electricityPlans = [];

  @override
  void initState() {
    super.initState();
    _registerService.loadUserData().then((_) {
      setState(() {}); // refresh UI after load
    });
    _loadElectricityPlans();
  }

  Future<void> _loadElectricityPlans() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("This is the user id: ${RegisterService.userId.toString()}");
    });
    setState(() => _isLoading = true);

    try {
      final electricityBills = await _billService.fetchBillersByCategory(
        'electricity',
      );

      final List<Map<String, dynamic>> allPlans = [];
      electricityBills.forEach((provider, plans) {
        allPlans.addAll(plans.map((plan) => plan as Map<String, dynamic>));
      });

      setState(() {
        _electricityPlans = allPlans;

        if (allPlans.isNotEmpty) {
          final firstPlan = allPlans.first;
          _selectedBillerCode = firstPlan['biller_code'];
          _selectedItemCode = firstPlan['item_code'];
          _selectedProvider =
              (firstPlan['name'] ?? "").toString().toUpperCase();
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Exception fetching electricity plans: $e");
      showCustomSnackBar(context, "Failed to load electricity plans");
    }
  }

  Future<void> _purchaseElectricity() async {
    final meterNumber = _meterController.text.trim();

    if (_selectedBillerCode == '' || _selectedItemCode == '') {
      showCustomSnackBar(context, "Please select a plan");
      return;
    }

    if (meterNumber.isEmpty) {
      showCustomSnackBar(context, "Please enter your Meter Number");
      return;
    }

    setState(() => _isLoading = true);

    final result = await _billService.purchaseElectricity(
      context: context,
      id: RegisterService.userId!,
      meterNumber: meterNumber,
      billerCode: _selectedBillerCode!,
      itemCode: _selectedItemCode!,
      amount: _selectedAmount,
    );

    setState(() => _isLoading = false);

    if (result.isNotEmpty && result["status"] == "success") {
      showCustomSnackBar(
        context,
        "Electricity purchase successful! Ref: ${result["data"]["reference"]}",
      );
    } else {
      showCustomSnackBar(context, "Electricity purchase failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlans =
        _electricityPlans.where((plan) {
          final name = plan['name']?.toString() ?? "";
          return _selectedProvider == null || name == _selectedProvider;
        }).toList();

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildPromoBanner(), // reuse if appropriate
                const SizedBox(height: 20),
                meterNumberSection(
                  context,
                  controller: _meterController,
                  electricityPlans: _electricityPlans,
                  selectedBillerCode: _selectedBillerCode,
                  onBillerChanged: (String? billerCode) {
                    setState(() {
                      _selectedBillerCode = billerCode;

                      final selectedPlan = _electricityPlans.firstWhere(
                        (plan) => plan['biller_code'] == billerCode,
                        orElse: () => {},
                      );

                      if (selectedPlan.isNotEmpty) {
                        _selectedItemCode =
                            selectedPlan['item_code']?.toString();
                        _selectedProvider =
                            (selectedPlan['name'] ?? "").toUpperCase();
                        final providerPlans =
                            _electricityPlans
                                .where(
                                  (p) => (p['name'] ?? "")
                                      .toUpperCase()
                                      .contains(_selectedProvider!),
                                )
                                .toList();
                        if (providerPlans.isNotEmpty) {
                          _selectedAmount =
                              providerPlans.first['amount']?.toString();
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                buildElectricityUssdBanner(context),
                const SizedBox(height: 40),
                buildPlanGrid(
                  plans: filteredPlans,
                  context: context,
                  selectedItemCode: _selectedItemCode,
                  selectedAmount: _selectedAmount,
                  onPlanSelected: (selectedPlan) {
                    setState(() {
                      _selectedAmount = selectedPlan['amount']?.toString();
                      _selectedBillerCode =
                          selectedPlan['biller_code']?.toString();
                      _selectedItemCode = selectedPlan['item_code']?.toString();
                    });
                  },
                ),
                const SizedBox(height: 48),
                buildBuyButton(
                  context: context,
                  isEnabled:
                      _selectedBillerCode != null &&
                      _meterController.text.trim().isNotEmpty,
                  isLoading: _isLoading,
                  onPressed: _purchaseElectricity,
                ),
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
