import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import 'package:transact_point/services/user-api-services.dart';
import './custom-widgets/data-widgets.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final ApiService _billService = ApiService();
  final RegisterService _registerService = RegisterService();
  String? _selectedNetwork; // New variable to track selected network
  String _selectedCategory = "HOT";
  bool _isLoading = true;
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedAmount;
  String? _selectedBillerCode; // Added missing variable
  String? _selectedItemCode;
  List<Map<String, dynamic>> _dataPlans = [];
  final List<String> categories = [
    "HOT",
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly",
    "XtraValue",
    "Broadband",
  ];

  // Helper function to assign virtual categories
  String getPlanCategory(Map<String, dynamic> plan) {
    final name = (plan['biller_name'] ?? "").toUpperCase();
    final amount = plan['amount'] ?? 0;

    // Match keywords first
    if (name.contains("BROADBAND")) return "Broadband";
    if (amount >= 5000) return "XtraValue"; // just an example
    if (amount <= 100) return "Daily";
    if (amount <= 500) return "Weekly";
    if (amount <= 2000) return "Monthly";
    if (amount > 2000) return "Yearly";

    // Default fallback
    return "HOT";
  }

  @override
  void initState() {
    super.initState();
    _registerService.loadUserData().then((_) {
      setState(() {}); // refresh UI after load
    });
    _loadDataPlans();
  }

  Future<void> _loadDataPlans() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("This is the user id: ${RegisterService.userId.toString()}");
    });
    setState(() => _isLoading = true);

    try {
      // Fetch 'data' plans using the service
      final dataBills = await _billService.fetchBillersByCategory('data');

      // The service now returns grouped data: {"MTN": [...], "AIRTEL": [...], ...}
      final Map<String, List<dynamic>> groupedPlans = dataBills;

      // Flatten all plans for displaying in the grid
      final List<Map<String, dynamic>> allPlans = [];
      groupedPlans.forEach((network, plans) {
        allPlans.addAll(plans.map((plan) => plan as Map<String, dynamic>));
      });

      // For auto-selection: one biller per network
      final Map<String, dynamic> networkBillers = {};
      groupedPlans.forEach((network, plans) {
        if (plans.isNotEmpty) {
          networkBillers[network] = plans.first;
        }
      });

      setState(() {
        _dataPlans = allPlans;

        // Auto-select MTN if available
        if (networkBillers.containsKey("MTN")) {
          _selectedBillerCode = networkBillers["MTN"]!['biller_code'];
          _selectedItemCode = networkBillers["MTN"]!['item_code'];
          _selectedNetwork = "MTN"; // ✅ Track the selected network
        } else if (networkBillers.isNotEmpty) {
          final firstNet = networkBillers.keys.first;
          _selectedBillerCode = networkBillers[firstNet]!['biller_code'];
          _selectedItemCode = networkBillers[firstNet]!['item_code'];
          _selectedNetwork = firstNet;
        }

        _isLoading = false;
      });

      print("Data plans loaded: $_dataPlans");
    } catch (e) {
      setState(() => _isLoading = false);
      print("Exception fetching data plans: $e");
      showCustomSnackBar(context, "Failed to load data plans");
    }
  }

  Future<void> _purchaseData() async {
    final phone = _phoneController.text.trim();

    if (_selectedBillerCode == '') {
      showCustomSnackBar(context, "Please select a network");
      return;
    }

    if (_selectedItemCode == '') {
      showCustomSnackBar(context, "Please select a data plan");
      return;
    }

    if (phone.isEmpty) {
      showCustomSnackBar(context, "Please enter valid phone and amount");
      return;
    }

    setState(() => _isLoading = true);

    await _billService.purchaseData(
      context: context,
      id: RegisterService.userId!,
      phone: phone,
      amount: _selectedAmount,
      billerCode: _selectedBillerCode!,
      itemCode: _selectedItemCode, // keep optional if null
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Filter plans by selected category
    final filteredPlans =
        _dataPlans.where((plan) {
          final matchesCategory = getPlanCategory(plan) == _selectedCategory;
          final matchesNetwork =
              _selectedNetwork == null
                  ? true
                  : (plan['name'] ?? "").toUpperCase().contains(
                    _selectedNetwork!,
                  );
          return matchesCategory && matchesNetwork;
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
                const SizedBox(height: 16),
                phoneNumberSection(
                  context,
                  controller: _phoneController,
                  dataPlans: _dataPlans,
                  selectedBillerCode: _selectedBillerCode,
                  onBillerChanged: (selectedCode) {
                    setState(() {
                      _selectedBillerCode = selectedCode;

                      // Find biller by code
                      final selectedBiller = _dataPlans.firstWhere(
                        (b) => b['biller_code'] == selectedCode,
                      );
                      _selectedItemCode = selectedBiller['item_code'];

                      // Update selected network based on the selected biller
                      final name = (selectedBiller['name'] ?? "").toUpperCase();
                      _selectedNetwork = billerLogos.keys.firstWhere(
                        (net) => name.contains(net),
                        orElse: () => "",
                      );
                    });
                  },
                ),
                const SizedBox(height: 24),
                buildUssdBanner(context),
                const SizedBox(height: 24),
                buildCategorySelector(
                  categories: categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
                  context: context,
                ),
                const SizedBox(height: 24),
                buildPlanGrid(
                  filteredPlans,
                  context,
                  selectedItemCode:
                      _selectedItemCode, // pass currently selected
                  selectedAmount: _selectedAmount,
                  onPlanSelected: (selectedPlan) {
                    setState(() {
                      _selectedAmount = selectedPlan['amount']?.toString();
                      _selectedBillerCode =
                          selectedPlan['biller_code']
                              ?.toString(); // ensure it's a string
                      _selectedItemCode = selectedPlan['item_code']?.toString();

                      final name = (selectedPlan['name'] ?? "").toUpperCase();
                      _selectedNetwork = billerLogos.keys.firstWhere(
                        (net) => name.contains(net),
                        orElse: () => "",
                      );
                    });
                  },
                ),

                const SizedBox(height: 48),
                buildBuyButton(
                  context: context,
                  isEnabled:
                      _selectedBillerCode != null &&
                      _phoneController.text.trim().isNotEmpty,
                  isLoading: _isLoading,
                  onPressed: _purchaseData,
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
