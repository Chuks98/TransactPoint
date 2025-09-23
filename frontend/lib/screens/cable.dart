import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import 'package:transact_point/services/user-api-services.dart';
import './custom-widgets/cable-widgets.dart'; // You can rename this if needed

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  final ApiService _billService = ApiService();
  final RegisterService _registerService = RegisterService();
  String? _selectedProvider; // Startimes, GOTV, DSTV
  bool _isLoading = true;
  final TextEditingController _smartCardController = TextEditingController();

  String? _selectedAmount;
  String? _selectedBillerCode;
  String? _selectedItemCode;
  List<Map<String, dynamic>> _cablePlans = [];

  @override
  void initState() {
    super.initState();
    _registerService.loadUserData().then((_) {
      setState(() {}); // refresh UI after load
    });
    _loadCablePlans();
  }

  Future<void> _loadCablePlans() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("This is the user id: ${RegisterService.userId.toString()}");
    });
    setState(() => _isLoading = true);

    try {
      // Fetch cabletv plans
      final cableBills = await _billService.fetchBillersByCategory('cabletv');

      // Flatten grouped plans
      final List<Map<String, dynamic>> allPlans = [];
      cableBills.forEach((provider, plans) {
        allPlans.addAll(plans.map((plan) => plan as Map<String, dynamic>));
      });

      setState(() {
        _cablePlans = allPlans;

        // Auto-select first provider if available
        if (allPlans.isNotEmpty) {
          final firstPlan = allPlans.first;
          _selectedBillerCode = firstPlan['biller_code'];
          _selectedItemCode = firstPlan['item_code'];
          final name = (firstPlan['name'] ?? "").toUpperCase();
          if (name.contains("STARTIMES"))
            _selectedProvider = "STARTIMES";
          else if (name.contains("DSTV"))
            _selectedProvider = "DSTV";
          else if (name.contains("GOTV"))
            _selectedProvider = "GOTV";
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Exception fetching cable plans: $e");
      showCustomSnackBar(context, "Failed to load cable plans");
    }
  }

  Future<void> _purchaseCable() async {
    final smartCard = _smartCardController.text.trim();

    if (_selectedBillerCode == null || _selectedItemCode == null) {
      showCustomSnackBar(context, "Please select a plan");
      return;
    }

    if (smartCard == '') {
      showCustomSnackBar(context, "Please enter a Smart Card number");
      return;
    }

    setState(() => _isLoading = true);

    final result = await _billService.purchaseCable(
      context: context,
      id: RegisterService.userId!,
      smartCard: smartCard,
      billerCode: _selectedBillerCode!,
      itemCode: _selectedItemCode!,
      amount: _selectedAmount,
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Filter plans by selected provider
    final filteredPlans =
        _cablePlans.where((plan) {
          final name = (plan['name'] ?? "").toUpperCase();
          return _selectedProvider == null || name.contains(_selectedProvider!);
        }).toList();

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildPromoBanner(),
                const SizedBox(height: 12),
                smartCardSection(
                  context,
                  controller: _smartCardController,
                  cablePlans: _cablePlans,
                  selectedBillerCode: _selectedBillerCode,
                  onBillerChanged: (String? billerCode) {
                    setState(() {
                      _selectedBillerCode = billerCode;

                      // Find the selected plan by biller_code
                      final selectedPlan = _cablePlans.firstWhere(
                        (plan) => plan['biller_code'] == billerCode,
                        orElse: () => {},
                      );

                      if (selectedPlan.isNotEmpty) {
                        _selectedItemCode =
                            selectedPlan['item_code']?.toString();

                        // Update provider based on name
                        final name = (selectedPlan['name'] ?? "").toUpperCase();
                        if (name.contains("DSTV"))
                          _selectedProvider = "DSTV";
                        else if (name.contains("GOTV"))
                          _selectedProvider = "GOTV";
                        else if (name.contains("STARTIMES"))
                          _selectedProvider = "STARTIMES";

                        // Optional: auto-select amount from first plan of that provider
                        final providerPlans =
                            _cablePlans
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

                const SizedBox(height: 12),
                buildCableUssdBanner(context),
                const SizedBox(height: 24),
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
                      _smartCardController.text.trim().isNotEmpty,
                  isLoading: _isLoading,
                  onPressed: _purchaseCable,
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
