import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart';
import '../utilities/countries.dart';
import '../services/flutterwave-api-services.dart'; // your RegisterService file

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? bankDetails;
  String selectedCountryCode = 'NG';
  bool loading = false;
  final apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final userJson = await storage.read(key: 'logged_in_user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);

      setState(() {
        bankDetails = {
          'account_name': userData['account_name'] ?? '',
          'account_number': userData['account_number'] ?? '',
          'bank_name': userData['bank_name'] ?? '',
          'country': userData['country'] ?? '',
          'currency_sign': userData['currency_sign'] ?? '',
        };
      });
    }
  }

  Future<void> _createVirtualAccount(String countryCode) async {
    setState(() => loading = true);

    try {
      final response = await apiService.createVirtualAccount(
        context: context,
        currencyCode: countryCode,
      );

      if (response != null) {
        // Save the returned account details in storage
        await storage.write(key: 'logged_in_user', value: jsonEncode(response));

        setState(() {
          bankDetails = response;
          selectedCountryCode = countryCode;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create account: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClipPath(
            clipper: UCurveClipper(),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: const Text(
                "Bank Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Currency selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  countryList.map((country) {
                    final code = country['code'];
                    final isSelected = selectedCountryCode == code;
                    return GestureDetector(
                      onTap: () => _createVirtualAccount(code),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          country['currency'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Details card
          Expanded(
            child:
                loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : bankDetails == null
                    ? const Center(child: Text('No bank details found'))
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                context,
                                "Account Name",
                                bankDetails!['account_name'],
                              ),
                              const Divider(),
                              _buildDetailRow(
                                context,
                                "Account Number",
                                bankDetails!['account_number'],
                              ),
                              const Divider(),
                              _buildDetailRow(
                                context,
                                "Bank Name",
                                bankDetails!['bank_name'],
                              ),
                              const Divider(),
                              _buildDetailRow(
                                context,
                                "Country",
                                bankDetails!['country'],
                              ),
                              const Divider(),
                              _buildDetailRow(
                                context,
                                "Currency",
                                bankDetails!['currency_sign'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
