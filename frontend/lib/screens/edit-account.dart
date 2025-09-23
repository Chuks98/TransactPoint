import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transact_point/screens/custom-widgets/wallet-widgets.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import 'package:transact_point/services/user-api-services.dart';
import 'package:transact_point/utilities/countries.dart';
import 'custom-widgets/snackbar.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  Map<String, dynamic>? selectedCountry;
  bool _loading = false;
  String? _rate;
  String? _targetCurrency;
  String? currentCurrency;
  String? walletBalance;
  String? currencySign;
  String? convertedBalance;

  /// 🔹 Fetch conversion rate
  Future<void> _getRate() async {
    print("Current Currency: $currentCurrency");
    print("Selected Country: $selectedCountry");
    if (currentCurrency == null || selectedCountry == null) {
      showCustomSnackBar(context, "Please select a currency first");
      return;
    }

    setState(() {
      _loading = true;
      _rate = null; // reset old values
      convertedBalance = null;
    });

    _targetCurrency = selectedCountry!['currency'];

    final apiService = ApiService();
    final data = await apiService.convertBalance(
      context: context,
      amount: walletBalance.toString(),
      fromCurrency: currentCurrency!,
      toCurrency: _targetCurrency!,
    );

    if (data != null && data["success"] == true) {
      setState(() {
        _rate = data["rate"].toString();
        convertedBalance = data["converted_amount"].toString();
      });
    }

    setState(() => _loading = false);
  }

  /// 🔹 Update account
  Future<void> _updateAccount() async {
    if (selectedCountry == null) {
      showCustomSnackBar(context, "Please select a country/currency");
      return;
    }
    if (convertedBalance == null) {
      showCustomSnackBar(context, "Please wait for conversion first");
      return;
    }

    setState(() => _loading = true);

    try {
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'logged_in_user');
      if (userJson == null) {
        showCustomSnackBar(context, "User not logged in");
        setState(() => _loading = false);
        return;
      }

      final user = jsonDecode(userJson);
      final userId = user['id'].toString();

      final response = await RegisterService().updateAccount(
        userId: userId,
        country: selectedCountry!['country'],
        currency: selectedCountry!['currency'],
        currencySign: selectedCountry!['currency_sign'],
        code: selectedCountry!['code'],
        amount: convertedBalance!,
      );

      if (response['status'] == 'success') {
        showCustomSnackBar(context, "Account updated successfully!");

        Navigator.pop(context, {
          'currency': selectedCountry!['currency'],
          'currencySign': selectedCountry!['currency_sign'],
          'balance': convertedBalance,
        });
      } else {
        showCustomSnackBar(
          context,
          response['message'] ?? "Failed to update account",
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
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    currentCurrency = args?['currentCurrency'];
    walletBalance = (args?['balance'] ?? '0');
    currencySign = args?['currencySign'];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update your account details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            buildWalletTopUpBanner(context),
            const SizedBox(height: 20),
            Text(
              "Account Balance: $currencySign $walletBalance",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select your country/currency"),
              value: selectedCountry,
              isExpanded: true,
              items:
                  countryList.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(
                        "${country['name']} (${country['currency']}, ${country['currency_sign']})",
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => selectedCountry = value);
                _getRate();
              },
            ),

            const SizedBox(height: 20),

            /// 🔹 Show progress bar + loader while fetching
            if (_loading) ...[
              LinearProgressIndicator(),
              const SizedBox(height: 12),
              Row(
                children: const [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text("Fetching conversion rate..."),
                ],
              ),
            ],

            /// 🔹 Show results when done loading
            if (!_loading && _rate != null && convertedBalance != null) ...[
              Text(
                "Rate: 1 $currentCurrency = $_rate $_targetCurrency\n"
                "Converted Balance: $convertedBalance $_targetCurrency",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _updateAccount,
              child:
                  _loading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Update Account"),
            ),
          ],
        ),
      ),
    );
  }
}
