import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final bool success;
  final String accountNumber;

  const ResultDialog({
    super.key,
    required this.success,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(success ? "Transfer Successful" : "Transfer Failed"),
      content: Text(
        success
            ? "Your transfer to $accountNumber was successful."
            : "Something went wrong. Please try again.",
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
