import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import 'package:transact_point/services/user-api-services.dart'; // <-- import your wallet API service
import 'package:transact_point/screens/custom-widgets/wallet-widgets.dart';
import 'custom-widgets/snackbar.dart';

class AccountFundingScreen extends StatefulWidget {
  const AccountFundingScreen({super.key});

  @override
  State<AccountFundingScreen> createState() => _AccountFundingScreenState();
}

class _AccountFundingScreenState extends State<AccountFundingScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? userWallet;

  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;
  final String? email = dotenv.env['EMAIL'];
  String? id;
  final String redirectUrl = "transactpoint://payment/callback";

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userJson = await secureStorage.read(key: 'logged_in_user');
    if (userJson != null) {
      final parsed = jsonDecode(userJson);
      setState(() {
        userData = parsed;
        id = parsed['id']?.toString();
      });
      if (id != null) {
        await _fetchUserWallet(id!);
      }
    }
  }

  Future<void> _fetchUserWallet(String userId) async {
    try {
      final response = await RegisterService().getWallet(userId);
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          userWallet = response['data'];
        });
      } else {
        showCustomSnackBar(
          context,
          response['message'] ?? "Failed to fetch wallet",
        );
      }
    } catch (e) {
      showCustomSnackBar(context, "Wallet fetch error: $e");
    }
  }

  void _fundAccount() async {
    final amount = _amountController.text.trim();

    if (amount.isEmpty) {
      showCustomSnackBar(context, "Please enter an amount");
      return;
    }

    if (id == null || id!.isEmpty) {
      showCustomSnackBar(context, "User ID not found. Please log in again.");
      return;
    }

    if (userWallet == null) {
      showCustomSnackBar(context, "Wallet not loaded. Please refresh.");
      return;
    }

    final currency = userWallet!['currency'];
    final code = userWallet!['code'];
    final currencySign = userWallet!['currencySign'];
    final country = userWallet!['country'];

    setState(() => _loading = true);

    try {
      final ApiService apiService = ApiService();
      final response = await apiService.fundAccount(
        context: context,
        amount: amount,
        currency: currency,
        email: email,
        id: id,
        redirectUrl: redirectUrl,
        code: code,
        currencySign: currencySign,
        country: country,
      );

      if (response['status'] == 'success' &&
          response['data']?['link'] != null) {
        final paymentLink = response['data']['link'];
        showCustomSnackBar(
          context,
          "Redirecting to payment for $currencySign$amount",
        );

        await launchUrl(
          Uri.parse(paymentLink),
          mode: LaunchMode.externalApplication,
        );
      } else {
        showCustomSnackBar(
          context,
          "Funding failed: ${response['message'] ?? "Unknown error"}",
        );
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletCurrencySign = userWallet?['currencySign'];
    final walletCurrency = userWallet?['currency'];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadUserData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildWalletTopUpBanner(context),
              const SizedBox(height: 20),
              if (userWallet != null) ...[
                Text(
                  "Wallet Balance: $walletCurrencySign${userWallet!['balance']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                "Enter Amount",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g. 5000",
                  prefixIcon: const Icon(Icons.account_balance),
                  prefixText: "$walletCurrencySign ",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _fundAccount,
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : const Text("Proceed to Funding"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
