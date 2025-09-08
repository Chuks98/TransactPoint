import 'package:flutter/material.dart';
import '../theme.dart';
import './custom-widgets/carousel.dart';
import '../services/flutterwave-api-services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;
  final String userFullName = "Chukwuma Onyedika";
  final double userBalance = 125000.75; // in naira

  final ApiService apiService = ApiService();
  Map<String, dynamic> _categories = {};
  final Map<String, dynamic> _customMenus = {
    "Transfer": {},
    "Invest": {},
    "Travel": {},
    "Shopping": {},
    "More": {},
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories(context);
  }

  Future<void> _loadCategories(BuildContext context) async {
    final cats = await apiService.fetchBillCategories(context);
    await apiService.fetchBillers();

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
      case "invest":
        return Icons.trending_up;
      case "transfer":
        return Icons.swap_horiz;
      case "travel":
        return Icons.flight_takeoff;
      case "shopping":
        return Icons.shopping_cart;
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
        // 🔹 Pull-to-refresh wrapper
        onRefresh: () => _loadCategories(context),
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Needed for RefreshIndicator
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
                      "subtitle": "Grow your money with Crest Finance",
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
                userFullName.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _isBalanceVisible
                        ? "₦${userBalance.toStringAsFixed(2)}"
                        : "₦******",
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

              /// 🔹 Show only category names
              !_loading && _categories.isNotEmpty
                  ? Column(
                    children: [
                      for (int i = 0; i < _categories.keys.length; i += 3)
                        _buildServiceGrid(
                          _categories.keys
                              .skip(i)
                              .take(3) // 🔹 Take 3 items per row
                              .map((categoryName) {
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      final routeName =
                                          categoryName.toLowerCase();

                                      if (_customMenus.containsKey(
                                        categoryName,
                                      )) {
                                        // 🔹 Navigate to your manual screen
                                        Navigator.pushNamed(
                                          context,
                                          '/$routeName',
                                        );
                                      } else {
                                        // 🔹 Navigate to API-based category
                                        Navigator.pushNamed(
                                          context,
                                          '/$routeName',
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getIconForCategory(categoryName),
                                            color: AppColors.primary,
                                            size: 36,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            categoryName.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
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
