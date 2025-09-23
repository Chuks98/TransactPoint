import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transact_point/screens/custom-widgets/bank-info-widget.dart';
import 'package:transact_point/screens/custom-widgets/date-formatter.dart';
import 'package:transact_point/theme.dart';
import 'package:transact_point/utilities/countries.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:transact_point/services/user-api-services.dart';
import 'package:transact_point/screens/custom-widgets/wallet-widgets.dart';
import 'custom-widgets/snackbar.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isBalanceVisible = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? userWallet;
  List<dynamic> transactions = [];
  bool _fetchingTransactions = false;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final TextEditingController _amountController = TextEditingController();

  bool _loading = false; // for wallet creation
  bool _fetchingWallet = true; // ✅ for wallet fetch state

  Map<String, dynamic>? selectedCountry;

  String? id;
  final String? email = dotenv.env['EMAIL'];
  final String redirectUrl = "transactpoint://payment/callback";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _fetchingWallet = true); // ✅ mark fetching start

    final userJson = await secureStorage.read(key: 'logged_in_user');
    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
        id = userData?['id']?.toString();
      });

      print(userData);
      if (id != null) {
        await _fetchUserWallet(id!);
        await _fetchRecentTransactions(id!); // ✅ also fetch transactions
      }
    }

    setState(() => _fetchingWallet = false); // ✅ mark fetching done
  }

  Future<void> _fetchUserWallet(String userId) async {
    try {
      final response = await RegisterService().getWallet(userId);
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          userWallet = response['data'];
        });
      }
    } catch (e) {
      showCustomSnackBar(context, "Failed to fetch wallet: $e");
    }
  }

  Future<void> _fetchRecentTransactions(String userId) async {
    setState(() => _fetchingTransactions = true);
    try {
      final result = await RegisterService().getUserRecentTransactions(userId);
      setState(() {
        transactions = result;
      });
    } catch (e) {
      showCustomSnackBar(context, "Failed to fetch transactions: $e");
    } finally {
      setState(() => _fetchingTransactions = false);
    }
  }

  Future<void> _createWallet() async {
    if (selectedCountry == null) {
      showCustomSnackBar(context, "Please select a currency/country");
      return;
    }
    if (id == null) {
      showCustomSnackBar(context, "User ID not found. Please log in again.");
      return;
    }

    setState(() => _loading = true);

    try {
      final payload = {
        'user_id': id,
        'currency': selectedCountry!['currency'],
        'code': selectedCountry!['code'],
        'currencySign': selectedCountry!['currency_sign'],
        'country': selectedCountry!['country'],
      };

      final response = await RegisterService().createWallet(payload);
      if (response['status'] == 'success') {
        setState(() {
          userWallet = response['data'];
        });
        showCustomSnackBar(context, "Account created successfully!");
      } else {
        showCustomSnackBar(
          context,
          response['message'] ?? "Failed to create account",
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
    /// CASE 1: Still fetching wallet → show loader
    if (_fetchingWallet) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// CASE 2: Wallet exists → show funding screen
    if (userWallet != null) {
      return buildFundingScreen();
    }

    /// CASE 3: No wallet → show create wallet screen
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi ${userData?['firstName'] ?? 'User'}, create your account to proceed",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            buildWalletTopUpBanner(context),
            const SizedBox(height: 20),
            DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select your country/currency"),
              value: selectedCountry,
              items:
                  countryList.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(
                        "${country['name']} (${country['currency']})",
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => selectedCountry = value);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _createWallet,
              child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFundingScreen() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final walletAmount = userWallet?['balance']?.toString();
    final walletCurrency = userWallet?['currency'];
    final walletCurrencySign = userWallet?['currencySign'];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData, // this will refresh user data and wallet
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics:
              const AlwaysScrollableScrollPhysics(), // required for RefreshIndicator
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildWalletTopUpBanner(context),
              const SizedBox(height: 20),

              /// Balance Card and conversion
              WalletBalanceWidget(
                isBalanceVisible: _isBalanceVisible,
                amount: walletAmount!,
                currency: walletCurrency,
                currencySign: walletCurrencySign,
                onToggleVisibility: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Change Currency", style: textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/edit-account',
                        arguments: {
                          'currentCurrency': walletCurrency,
                          'balance': userWallet!['balance'],
                          'currencySign': userWallet?['currencySign'],
                        },
                      ).then((_) {
                        _loadUserData(); // refresh wallet after returning
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                  ),
                ],
              ),
              Divider(color: AppColors.grey.withOpacity(0.5)),
              const SizedBox(height: 30),

              BankInfoWidget(
                bankName: userData?['bank_name'],
                accountName: userData?['account_name'],
                accountNumber: userData?['account_number'],
                country: userData?['country'],
              ),
              Divider(color: AppColors.grey.withOpacity(0.5)),
              const SizedBox(height: 30),

              /// Quick Actions
              Text("Quick Actions", style: textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  actionButton(
                    icon: Icons.send_rounded,
                    label: "Transfer",
                    onTap:
                        () =>
                            Navigator.pushNamed(context, '/transfer').then((_) {
                              _loadUserData(); // refresh wallet after funding
                            }),
                  ),
                  actionButton(
                    icon: Icons.account_balance_wallet,
                    label: "Fund Account",
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          '/fund-account',
                        ).then((_) {
                          _loadUserData(); // refresh wallet after funding
                        }),
                  ),
                  actionButton(
                    icon: Icons.receipt_long,
                    label: "Pay Bills",
                    onTap:
                        () => Navigator.pushNamed(context, '/home').then((_) {
                          _loadUserData(); // refresh wallet after funding
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: AppColors.grey.withOpacity(0.5)),
              const SizedBox(height: 24),

              /// Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Transactions", style: textTheme.titleMedium),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/transactions').then((_) {
                        _loadUserData();
                      });
                    },
                    child: Text(
                      "See More",
                      style: textTheme.bodySmall!.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_fetchingTransactions)
                const Center(child: CircularProgressIndicator())
              else if (transactions.isEmpty)
                const Text("No transactions yet.")
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          tx['status'] != 'successful'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color:
                              tx['status'] != 'successful'
                                  ? Colors.red
                                  : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        tx['description'] ?? 'Transaction',
                        style: textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        DateFormatter.formatDate(tx['created_at']),
                        style: textTheme.bodySmall!.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      trailing: Text(
                        "${tx['status'] != 'successful' ? '-' : '+'} ${tx['currencySign']}${tx['amount']}",
                        style: textTheme.bodyMedium!.copyWith(
                          color:
                              tx['status'] != 'successful'
                                  ? Colors.red
                                  : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
