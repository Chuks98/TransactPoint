import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/confirm-dialog.dart';
import 'package:transact_point/screens/custom-widgets/loader-dialog.dart';
import 'package:transact_point/screens/custom-widgets/result-dialog.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/utilities/countries.dart';

import 'package:transact_point/screens/custom-widgets/transfer-widgets.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? selectedCountry;
  String? selectedBankCode;
  String? selectedBankName;
  String? accountNumber;
  String? amount;
  String? description;
  String? beneficiaryName;
  String? swiftCode;
  String? beneficiaryAddress;
  String? beneficiaryCity;
  bool isInternational = false;
  bool isFetchingName = false;

  List<Map<String, String>> banks = [];
  bool isLoadingBanks = false;

  bool isFormValid = false; // 👈 Track validity

  void _checkFormValidity() {
    setState(() {
      if (isInternational) {
        isFormValid =
            (accountNumber?.isNotEmpty ?? false) &&
            (amount?.isNotEmpty ?? false) &&
            (beneficiaryName?.isNotEmpty ?? false) &&
            (swiftCode?.isNotEmpty ?? false) &&
            (beneficiaryCity?.isNotEmpty ?? false) &&
            (beneficiaryAddress?.isNotEmpty ?? false);
      } else if (!isInternational) {
        isFormValid =
            (selectedCountry?.isNotEmpty ?? false) &&
            (selectedBankCode?.isNotEmpty ?? false) &&
            (accountNumber?.isNotEmpty ?? false) &&
            (amount?.isNotEmpty ?? false);
      }
    });
  }

  void _onCountrySelected(String countryCode) async {
    setState(() {
      selectedCountry = countryCode;

      // Check from your JSON if this is international
      isInternational = countryCode.startsWith("INT_");
      banks = [];
      selectedBankCode = null;
      selectedBankName = null;
      isLoadingBanks = true; // 👈 Start loading
    });

    if (!isInternational) {
      try {
        final fetchedBanks = await _apiService.fetchBanks(countryCode, context);

        setState(() {
          banks = fetchedBanks!; // 👈 assign the fetched banks
        });
      } catch (e) {
        print("Error fetching banks: $e");
      } finally {
        setState(() {
          isLoadingBanks = false; // 👈 stop loading
        });
      }
    } else {
      setState(() {
        isLoadingBanks = false; // not local, no banks to fetch
      });
    }
  }

  Future<void> _resolveAccountName(BuildContext context) async {
    setState(() => isFetchingName = true);
    try {
      final name = await _apiService.resolveAccountName(
        context: context,
        accountNumber: accountNumber!,
        bankCode: selectedBankCode!,
      );
      setState(() {
        beneficiaryName = name;
      });
    } catch (e) {
      showCustomSnackBar(context, e.toString());
      print("Error resolving account: $e");
    } finally {
      setState(() => isFetchingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: promoBanner(),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Country selector
                    BounceInLeft(
                      delay: const Duration(milliseconds: 150),
                      child: countryDropdown(
                        selectedCountry: selectedCountry,
                        countryList:
                            countryList
                                .map(
                                  (e) => e.map(
                                    (key, value) =>
                                        MapEntry(key, value.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _onCountrySelected(val);
                          }
                          _checkFormValidity();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!isInternational)
                      BounceInLeft(
                        delay: const Duration(milliseconds: 200),
                        child: bankDropdown(
                          isLoadingBanks: isLoadingBanks,
                          banks: banks,
                          selectedBankCode: selectedBankCode,
                          selectedBankName: selectedBankName,
                          onChanged: (val) {
                            setState(() {
                              selectedBankCode = val;
                              // Also update the selectedBankName if you pass it through
                              final selectedBank = banks?.firstWhere(
                                (b) => b['code'] == val,
                                orElse: () => {'name': '', 'code': ''},
                              );
                              selectedBankName = selectedBank?['name'];
                            });
                            _checkFormValidity(); // call after state update
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    BounceInLeft(
                      delay: const Duration(milliseconds: 250),
                      child: accountNumberField(
                        isInternational: isInternational,
                        accountNumber: accountNumber,
                        beneficiaryName: beneficiaryName,
                        isFetchingName: isFetchingName,
                        onChanged: (val) {
                          accountNumber = val;
                          _checkFormValidity();

                          // Only fetch for local banks and valid length
                          if (!isInternational &&
                              val.length >= 10 &&
                              selectedBankCode != null) {
                            _resolveAccountName(context);
                          } else {
                            // Reset name if invalid
                            setState(() => beneficiaryName = null);
                          }
                        },
                      ),
                    ),

                    // Extra fields if international
                    if (isInternational) ...[
                      BounceInLeft(
                        delay: const Duration(milliseconds: 300),
                        child: buildCustomTextField(
                          label: "Beneficiary Name",
                          onSaved: (val) => beneficiaryName = val,

                          onChanged: (val) {
                            beneficiaryName = val;
                            _checkFormValidity(); // still optional, won’t block button
                          },
                        ),
                      ),
                      BounceInLeft(
                        delay: const Duration(milliseconds: 350),
                        child: buildCustomTextField(
                          label: "SWIFT Code",
                          onSaved: (val) => swiftCode = val,
                          onChanged: (val) {
                            swiftCode = val;
                            _checkFormValidity(); // still optional, won’t block button
                          },
                        ),
                      ),
                      BounceInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: buildCustomTextField(
                          label: "Beneficiary Address",
                          onSaved: (val) => beneficiaryAddress = val,
                          onChanged: (val) {
                            beneficiaryAddress = val;
                            _checkFormValidity(); // still optional, won’t block button
                          },
                        ),
                      ),
                      BounceInLeft(
                        delay: const Duration(milliseconds: 450),
                        child: buildCustomTextField(
                          label: "City",
                          onSaved: (val) => beneficiaryCity = val,
                          onChanged: (val) {
                            beneficiaryCity = val;
                            _checkFormValidity(); // still optional, won’t block button
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // International transfer banner
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: internationalTransferBanner(context),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    BounceInLeft(
                      delay: const Duration(milliseconds: 550),
                      child: buildCustomTextField(
                        label: "Amount",
                        onSaved: (val) => amount = val,
                        validator:
                            (val) =>
                                val == null || double.tryParse(val) == null
                                    ? "Enter valid amount"
                                    : null,
                        onChanged: (val) {
                          amount = val;
                          _checkFormValidity(); // still optional, won’t block button
                        },
                      ),
                    ),

                    // Description
                    BounceInLeft(
                      delay: const Duration(milliseconds: 600),
                      child: buildCustomTextField(
                        label: "Description (Optional)",
                        onSaved: (val) => description = val,
                        // No validator since it's optional
                        validator: (_) => null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 650),
                      child: ElevatedButton(
                        onPressed:
                            isFormValid
                                ? () {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    _showConfirmationDialog();
                                  }
                                }
                                : null, // 👈 disabled when invalid
                        child: const Text("Continue"),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmDialog(
          title: "Confirm Transfer",
          content: [
            Text("Country: $selectedCountry"),
            if (!isInternational) Text("Bank: $selectedBankName"),
            Text("Name: $beneficiaryName"),
            Text("Account: $accountNumber"),
            Text("Amount: $amount"),
            if (description?.isNotEmpty ?? false) Text("Note: $description"),
            if (isInternational) ...[
              Text("Beneficiary: $beneficiaryName"),
              Text("SWIFT CODE: $swiftCode"),
              Text("Address: $beneficiaryAddress, $beneficiaryCity"),
            ],
          ],
          onConfirm: () {
            Navigator.pop(ctx);
            _processTransfer();
          },
        );
      },
    );
  }

  void _processTransfer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const LoaderDialog(message: "Processing your transfer..."),
    );

    try {
      final success = await _apiService.transfer(
        context: context,
        accountBank: isInternational ? null : selectedBankCode!,
        accountNumber: accountNumber!,
        amount: double.tryParse(amount!) ?? 0.0,
        currency: isInternational ? "USD" : "NGN",
        description: description ?? "Wallet Transfer",
        country: isInternational ? selectedCountry : null,
        swiftCode: isInternational ? swiftCode : null,
        beneficiaryName: isInternational ? beneficiaryName : null,
        beneficiaryAddress: isInternational ? beneficiaryAddress : null,
        beneficiaryCity: isInternational ? beneficiaryCity : null,
      );

      Navigator.pop(context); // close loader

      _showResultDialog(success: success);

      if (success) {
        print("✅ Transfer Success");
        setState(() {
          selectedBankCode = isInternational ? selectedBankCode : '';
          accountNumber = '';
          amount = '';
          description = '';
          swiftCode = '';
          beneficiaryName = '';
          beneficiaryAddress = '';
          beneficiaryCity = '';
        });
      } else {
        print("❌ Transfer Failed (API returned false)");
      }
    } catch (e) {
      Navigator.pop(context);
      _showResultDialog(success: false);
      print("❌ Transfer Failed: $e");
    }
  }

  void _showResultDialog({required bool success}) {
    showDialog(
      context: context,
      builder:
          (_) => ResultDialog(
            title: success ? "Transfer Successful" : "Transfer Failed",
            message:
                success
                    ? "Your transfer to $accountNumber was successful."
                    : "Something went wrong. Please try again.",
          ),
    );
  }
}
