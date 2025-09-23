import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme.dart';
import './custom-widgets/carousel.dart';
import '../services/flutterwave-api-services.dart';
import '../services/user-api-services.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  String userFullName = "";
  String userBalance = "0.0";
  String? currencySign; // default
  String? userId;

  final storage = const FlutterSecureStorage();
  final ApiService apiService = ApiService();
  final RegisterService registerService = RegisterService();
  final NumberFormat currencyFormatter = NumberFormat("#,##0.00", "en_US");

  Map<String, dynamic> _categories = {};
  final Map<String, dynamic> _customMenus = {
    "Transfer": {},
    "My Account": {},
    "My Bank Details": {},
    "More": {},
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories(context);
  }

  Future<void> _loadUserData() async {
    try {
      // 🔹 Get stored user JSON
      String? userJson = await storage.read(key: "logged_in_user");
      if (userJson == null) return;

      final userMap = jsonDecode(userJson);
      final firstName = userMap['firstName'] ?? "";
      final lastName = userMap['lastName'] ?? "";
      userId = userMap['id']?.toString();

      setState(() {
        userFullName = "$firstName $lastName".trim();
      });

      // 🔹 Fetch wallet from API
      if (userId != null) {
        final walletRes = await registerService.getWallet(userId!);
        print(walletRes);
        if (walletRes['status'] == 'success' && walletRes['data'] != null) {
          final walletData = walletRes['data'];
          setState(() {
            userBalance = (walletData['balance']).toString();
            currencySign = walletData['currencySign']; // fallback
          });
        }
      }
    } catch (e) {
      print("🚨 _loadUserData error: $e");
    }
  }

  Future<void> _loadCategories(BuildContext context) async {
    final cats = await apiService.fetchBillCategories(context);
    setState(() {
      _categories = {...cats, ..._customMenus};
      _loading = false;
    });
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case "airtime":
        return Icons.phone_android;
      case "data":
        return Icons.wifi;
      case "power":
      case "electricity":
        return Icons.lightbulb_outline;
      case "cabletv":
      case "tv":
        return Icons.tv;
      case "transfer":
        return Icons.swap_horiz;
      case "my account":
        return Icons.account_balance_wallet;
      case "bank-details":
        return Icons.money;
      case "more":
        return Icons.more_horiz;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadCategories(context);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Carousel
              SizedBox(
                width: double.infinity,
                child: CustomCarousel(
                  items: const [
                    {
                      "icon": "0xe0af",
                      "title": "Pay Bills Easily",
                      "subtitle": "Electricity, Cable, Internet & more",
                    },
                    {
                      "icon": "0xe041",
                      "title": "Invest Smartly",
                      "subtitle": "Grow your money with us",
                    },
                    {
                      "icon": "0xe1bc",
                      "title": "Quick Airtime & Data",
                      "subtitle": "Recharge instantly anytime",
                    },
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 User Info
              Text(
                userFullName.isNotEmpty
                    ? userFullName.toUpperCase()
                    : "LOADING...",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _isBalanceVisible
                        ? "${currencySign ?? ""} ${currencyFormatter.format(double.tryParse(userBalance) ?? 0)}"
                            .trim()
                        : "${currencySign ?? ""}${"******"}".trim(),

                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    iconSize: 18,
                    onPressed: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔹 Categories
              !_loading && _categories.isNotEmpty
                  ? Column(
                    children: [
                      for (int i = 0; i < _categories.keys.length; i += 3)
                        _buildServiceGrid(
                          _categories.keys.skip(i).take(3).map((categoryName) {
                            return SizedBox(
                              height: 110, // 🔹 fixed height for all boxes
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    final routeName =
                                        categoryName.toLowerCase();
                                    Navigator.pushNamed(
                                      context,
                                      '/$routeName',
                                    ).then((_) {
                                      _loadUserData();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _getIconForCategory(categoryName),
                                            color: AppColors.primary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          categoryName.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          maxLines: 1, // 🔹 single line only
                                          overflow:
                                              TextOverflow
                                                  .ellipsis, // 🔹 cut off if too long
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  )
                  : const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(List<Widget> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: item,
                  ),
                ),
              )
              .toList(),
    );
  }
}
