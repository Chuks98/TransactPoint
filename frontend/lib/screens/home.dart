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
<<<<<<< HEAD
    "Savings": {},
=======
    "More": {},
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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

<<<<<<< HEAD
      final userMap = jsonDecode(userJson) as Map<String, dynamic>? ?? {};
=======
      final userMap = jsonDecode(userJson);
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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
<<<<<<< HEAD
      case "my bank details":
        return Icons.money;
      case "savings":
        return Icons.savings;
=======
      case "bank-details":
        return Icons.money;
      case "more":
        return Icons.more_horiz;
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
      default:
        return Icons.more_horiz;
    }
  }

<<<<<<< HEAD
  String _formatBalance(String balance) {
    try {
      final value = double.tryParse(balance) ?? 0.0;
      return currencyFormatter.format(value);
    } catch (e) {
      print("Balance formatting failed: $e");
      return balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData apptheme = Theme.of(context);
=======
  @override
  Widget build(BuildContext context) {
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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
<<<<<<< HEAD
                      "title": "Pay Bills Easily",
                      "subtitle": "Electricity, Cable, Internet & more",
                      "icon": Icons.receipt_long, // ✅ use constant
                    },
                    {
                      "title": "Invest Smartly",
                      "subtitle": "Grow your money with us",
                      "icon": Icons.trending_up,
                    },
                    {
                      "title": "Quick Airtime & Data",
                      "subtitle": "Recharge instantly anytime",
                      "icon": Icons.phone_android,
=======
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
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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
<<<<<<< HEAD
                    // _isBalanceVisible
                    //     ? "${currencySign ?? ""} ${currencyFormatter.format(double.tryParse(userBalance) ?? 0)}"
                    //         .trim()
                    //     : "${currencySign ?? ""}${"******"}".trim(),
                    _isBalanceVisible
                        ? "${currencySign ?? ""} ${_formatBalance(userBalance)}"
                        : "${currencySign ?? ""}******",
=======
                    _isBalanceVisible
                        ? "${currencySign ?? ""} ${currencyFormatter.format(double.tryParse(userBalance) ?? 0)}"
                            .trim()
                        : "${currencySign ?? ""}${"******"}".trim(),
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9

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
<<<<<<< HEAD
                  ? Builder(
                    builder: (context) {
                      final keysList = _categories.keys.toList();

                      return Column(
                        children: [
                          for (
                            int batchStart = 0;
                            batchStart < keysList.length;
                            batchStart += 6
                          )
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: apptheme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  for (
                                    int rowStart = batchStart;
                                    rowStart < batchStart + 6 &&
                                        rowStart < keysList.length;
                                    rowStart += 3
                                  ) ...[
                                    _buildServiceGrid(
                                      keysList
                                          .skip(rowStart)
                                          .take(3)
                                          .map(
                                            (categoryName) => SizedBox(
                                              height: 95,
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/${categoryName.toLowerCase()}',
                                                    ).then(
                                                      (_) => _loadUserData(),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: AppColors
                                                                    .primary
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                          child: Icon(
                                                            _getIconForCategory(
                                                              categoryName,
                                                            ),
                                                            color:
                                                                AppColors
                                                                    .primary,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          categoryName
                                                              .toUpperCase(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    if (rowStart + 3 < batchStart + 6 &&
                                        rowStart + 3 < keysList.length)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
=======
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
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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
