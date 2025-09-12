import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../theme.dart';

// Promo Banner
Widget promoBanner() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      'assets/images/promo.png',
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  );
}

Widget internationalTransferBanner(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [AppColors.primary, Colors.blue.shade800],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        children: const [
          TextSpan(
            text: 'International Transfers Made Easy\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(text: 'Send money securely from '),
          TextSpan(
            text: 'France, Spain, Japan, USA etc ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: 'to Nigeria — anytime, anywhere.'),
        ],
      ),
    ),
  );
}

/// Country dropdown
Widget countryDropdown({
  required String? selectedCountry,
  required List<Map<String, String>> countryList,
  required void Function(String?) onChanged,
}) {
  return DropdownButtonFormField<String>(
    decoration: const InputDecoration(labelText: "Select Country"),
    value: selectedCountry,
    items:
        countryList
            .map(
              (c) => DropdownMenuItem<String>(
                value: c["code"],
                child: Text(c["name"]!),
              ),
            )
            .toList(),
    onChanged: onChanged,
    validator: (val) => val == null ? "Please select a country" : null,
  );
}

Widget bankDropdown({
  required bool isLoadingBanks,
  required List<Map<String, String>>? banks,
  required String? selectedBankCode,
  required String? selectedBankName,
  required void Function(String?) onChanged,
}) {
  if (isLoadingBanks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text("Fetching banks..."),
          ],
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(minHeight: 4),
      ],
    );
  }

  final List<Map<String, String>> bankList = banks ?? [];

  return DropdownSearch<Map<String, String>>(
    selectedItem: bankList.firstWhere(
      (b) => b['code'] == selectedBankCode,
      orElse: () => {'code': '', 'name': ''},
    ),
    dropdownDecoratorProps: DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
        labelText: "Select Bank Here", // Placeholder
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
    // Provide a callback to filter/search items
    asyncItems: (String filter) async {
      return bankList
          .where((b) => b['name']!.toLowerCase().contains(filter.toLowerCase()))
          .toList();
    },
    itemAsString: (Map<String, String>? b) => b?['name'] ?? '',
    onChanged:
        (selected) => {
          onChanged(selected?['code']),
          selectedBankName = selected?['name'],
        },
    validator:
        (val) =>
            (val == null || val['code']?.isEmpty == true)
                ? "Please select a bank"
                : null,
    popupProps: PopupProps.menu(
      showSearchBox: true,
      searchFieldProps: TextFieldProps(
        decoration: const InputDecoration(hintText: 'Search bank here...'),
      ),
    ),
  );
}

/// Account number field
Widget accountNumberField({
  required bool isInternational,
  required String? accountNumber,
  required String? beneficiaryName,
  required bool isFetchingName,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        decoration: InputDecoration(
          labelText:
              isInternational ? "IBAN / Account Number" : "Account Number",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: TextInputType.text,
        onChanged: onChanged,
        validator:
            (val) => val == null || val.isEmpty ? "Enter account number" : null,
      ),
      const SizedBox(height: 8),
      if (isFetchingName)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text("Fetching account name..."),
              ],
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 4),
          ],
        )
      else if (beneficiaryName != null && beneficiaryName.isNotEmpty)
        Text(
          "Account Name: $beneficiaryName",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
    ],
  );
}

// ✅ Widget function (not a class)
Widget buildCustomTextField({
  required String label,
  required FormFieldSetter<String> onSaved,
  String? Function(String?)? validator,
  ValueChanged<String>? onChanged,
}) {
  return Column(
    children: [
      const SizedBox(height: 16),
      TextFormField(
        decoration: InputDecoration(labelText: label),
        onSaved: onSaved,
        onChanged: onChanged,
        validator:
            validator ??
            (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    ],
  );
}
