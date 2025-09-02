import 'package:flutter/material.dart';
import './custom-widgets/service-item.dart';
import './custom-widgets/carousel.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;

  final String userFullName = "Chukwuma Onyedika";
  final double userBalance = 125000.75; // in naira

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Full-width Carousel
            SizedBox(
              width: double.infinity,
              child: CustomCarousel(
                items: const [
                  {
                    "icon": "0xe0af", // 🔌 Icons.lightbulb_outline
                    "title": "Pay Bills Easily",
                    "subtitle": "Electricity, Cable, Internet & more",
                  },
                  {
                    "icon": "0xe041", // 📈 Icons.trending_up
                    "title": "Invest Smartly",
                    "subtitle": "Grow your money with Crest Finance",
                  },
                  {
                    "icon": "0xe1bc", // 📱 Icons.phone_android
                    "title": "Quick Airtime & Data",
                    "subtitle": "Recharge instantly anytime",
                  },
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 User Fullname
            Text(
              userFullName.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            /// 🔹 User Balance with eye toggle
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
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
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

            /// 🔹 Services Grid (Row 1)
            _buildServiceGrid([
              ServiceItem(
                icon: Icons.phone_android,
                label: "Airtime",
                onTap: () {
                  Navigator.pushNamed(context, '/airtime');
                },
              ),
              ServiceItem(
                icon: Icons.wifi,
                label: "Data",
                onTap: () {
                  Navigator.pushNamed(context, '/data');
                },
              ),
              ServiceItem(
                icon: Icons.lightbulb_outline,
                label: "Electricity",
                onTap: () {
                  Navigator.pushNamed(context, '/electricity');
                },
              ),
            ]),

            const SizedBox(height: 16),

            /// 🔹 Services Grid (Row 2)
            _buildServiceGrid([
              ServiceItem(
                icon: Icons.account_balance,
                label: "Loans",
                onTap: () {
                  Navigator.pushNamed(context, '/loan');
                },
              ),
              ServiceItem(
                icon: Icons.trending_up,
                label: "Invest",
                onTap: () {
                  Navigator.pushNamed(context, '/invest');
                },
              ),
              ServiceItem(
                icon: Icons.receipt_long,
                label: "Bills",
                onTap: () {
                  Navigator.pushNamed(context, '/bills');
                },
              ),
            ]),

            const SizedBox(height: 16),

            /// 🔹 More Services (Row 3)
            _buildServiceGrid([
              ServiceItem(
                icon: Icons.security,
                label: "Insurance",
                onTap: () {
                  Navigator.pushNamed(context, '/insurance');
                },
              ),
              ServiceItem(
                icon: Icons.shopping_cart,
                label: "Shopping",
                onTap: () {
                  Navigator.pushNamed(context, '/shopping');
                },
              ),
              ServiceItem(
                icon: Icons.flight_takeoff,
                label: "Travel",
                onTap: () {
                  Navigator.pushNamed(context, '/travel');
                },
              ),
            ]),

            const SizedBox(height: 16),

            _buildServiceGrid([
              ServiceItem(
                icon: Icons.tv,
                label: "Cable TV",
                onTap: () {
                  Navigator.pushNamed(context, '/cable');
                },
              ),
              ServiceItem(
                icon: Icons.savings,
                label: "Savings",
                onTap: () {
                  Navigator.pushNamed(context, '/savings');
                },
              ),
              ServiceItem(
                icon: Icons.more_horiz,
                label: "More",
                onTap: () {
                  Navigator.pushNamed(context, '/more');
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  /// 🔹 Helper: build a row of ServiceItems
  Widget _buildServiceGrid(List<Widget> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: item,
                  ),
                ),
              )
              .toList(),
    );
  }
}
