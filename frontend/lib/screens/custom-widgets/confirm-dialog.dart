import 'package:flutter/material.dart';
import '../../theme.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final List<Widget> content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmText = "Confirm",
    this.cancelText = "Cancel",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context),
          child: Text(
            cancelText,
            style: const TextStyle(color: AppColors.grey),
          ),
        ),
        ElevatedButton(onPressed: onConfirm, child: Text(confirmText)),
      ],
    );
  }
}
