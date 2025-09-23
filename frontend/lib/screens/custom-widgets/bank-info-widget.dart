import 'package:flutter/material.dart';
import 'package:transact_point/theme.dart';

class BankInfoWidget extends StatelessWidget {
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? country;

  const BankInfoWidget({
    super.key,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bank Information", style: textTheme.titleMedium),
            const SizedBox(height: 12),
            _infoRow("Bank Name", bankName ?? "N/A"),
            _infoRow("Account Name", accountName ?? "N/A"),
            _infoRow("Account Number", accountNumber ?? "N/A"),
            _infoRow("Country", country ?? "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
