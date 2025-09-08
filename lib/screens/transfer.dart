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
      isFormValid =
          (selectedCountry?.isNotEmpty ?? false) &&
          (selectedBankCode?.isNotEmpty ?? false) &&
          (accountNumber?.isNotEmpty ?? false) &&
          (amount?.isNotEmpty ?? false) &&
          (!isInternational ||
              ((beneficiaryName?.isNotEmpty ?? false) &&
                  (swiftCode?.isNotEmpty ?? false) &&
                  (beneficiaryAddress?.isNotEmpty ?? false) &&
                  (beneficiaryCity?.isNotEmpty ?? false)));
    });
  }

  void _onCountrySelected(String countryCode) async {
    setState(() {
      selectedCountry = countryCode;

      // Check from your JSON if this is international
      isInternational = countryCode.startsWith("INT_");
      banks = [];
      selectedBankCode = null;
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
              promoBanner(),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Country selector
                    countryDropdown(
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
                        _checkFormValidity(); // 👈
                        if (val != null) _onCountrySelected(val);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (!isInternational)
                      bankDropdown(
                        isLoadingBanks: isLoadingBanks,
                        banks: banks,
                        selectedBankCode: selectedBankCode,
                        onChanged: (val) {
                          _checkFormValidity(); // 👈
                          selectedBankCode = val;
                        },
                      ),
                    const SizedBox(height: 16),

                    accountNumberField(
                      isInternational: isInternational,
                      accountNumber: accountNumber,
                      beneficiaryName: beneficiaryName,
                      isFetchingName: isFetchingName,
                      onChanged: (val) {
                        _checkFormValidity();
                        accountNumber = val;

                        // Only fetch for local banks and valid length
                        if (!isInternational &&
                            val.length >= 10 &&
                            selectedBankCode != null) {
                          _resolveAccountName(context);
                        } else {
                          // Reset name if invalid
                          setState(() => beneficiaryName = '');
                        }
                      },
                    ),

                    accountName(
                      isFetchingName: isFetchingName,
                      beneficiaryName: beneficiaryName,
                      onChanged: (val) {
                        beneficiaryName = val;
                        _checkFormValidity(); // still optional, won’t block button
                      },
                    ),
                    // Extra fields if international
                    if (isInternational) ...[
                      buildCustomTextField(
                        label: "Beneficiary Name",
                        onSaved: (val) => beneficiaryName = val,

                        onChanged: (val) {
                          beneficiaryName = val;
                          _checkFormValidity(); // still optional, won’t block button
                        },
                      ),
                      buildCustomTextField(
                        label: "SWIFT Code",
                        onSaved: (val) => swiftCode = val,
                        onChanged: (val) {
                          swiftCode = val;
                          _checkFormValidity(); // still optional, won’t block button
                        },
                      ),
                      buildCustomTextField(
                        label: "Beneficiary Address",
                        onSaved: (val) => beneficiaryAddress = val,
                        onChanged: (val) {
                          beneficiaryAddress = val;
                          _checkFormValidity(); // still optional, won’t block button
                        },
                      ),
                      buildCustomTextField(
                        label: "City",
                        onSaved: (val) => beneficiaryCity = val,
                        onChanged: (val) {
                          beneficiaryCity = val;
                          _checkFormValidity(); // still optional, won’t block button
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    internationalTransferBanner(context),
                    const SizedBox(height: 16),

                    // Amount
                    buildCustomTextField(
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

                    // Description
                    buildCustomTextField(
                      label: "Description (Optional)",
                      onSaved: (val) => description = val,
                      // No validator since it's optional
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
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
            Text("Bank Code: $selectedBankCode"),
            Text("Account: $accountNumber"),
            Text("Amount: $amount"),
            if (description?.isNotEmpty ?? false) Text("Note: $description"),
            if (isInternational) ...[
              Text("Beneficiary: $beneficiaryName"),
              Text("SWIFT: $swiftCode"),
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
      final result = await _apiService.transfer(
        accountBank: selectedBankCode!,
        accountNumber: accountNumber!,
        amount: double.tryParse(amount!) ?? 0.0,
        currency: isInternational ? "USD" : "NGN",
        narration: description ?? "Wallet Transfer",
        country: isInternational ? selectedCountry : null,
        swiftCode: isInternational ? swiftCode : null,
        beneficiaryName: isInternational ? beneficiaryName : null,
        beneficiaryAddress: isInternational ? beneficiaryAddress : null,
        beneficiaryCity: isInternational ? beneficiaryCity : null,
      );

      Navigator.pop(context); // close loader
      _showResultDialog(success: true);
      print("✅ Transfer Success: $result");
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
          (_) => ResultDialog(success: success, accountNumber: accountNumber!),
    );
  }
}
