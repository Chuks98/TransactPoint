import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;

  const ResultDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = "OK",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
