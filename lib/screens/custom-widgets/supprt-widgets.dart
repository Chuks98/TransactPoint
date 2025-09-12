import 'package:flutter/material.dart';
import '../../theme.dart';

Widget buildSupportBanner(BuildContext context) {
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
            text: 'Need Help?\n',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          TextSpan(
            text:
                'Our support team is always ready to assist you with transfers, wallet top-ups, or any other questions.\n',
          ),
          TextSpan(
            text: '📧 support@transactpoint.com   📞 +1 800 123 4567',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
