import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(rawDate);
      // Example format: Sun 13 April, 2024 3:00pm
      final formatter = DateFormat('EEE d MMMM, yyyy h:mma');
      return formatter.format(dateTime).toLowerCase(); // makes am/pm lowercase
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }
}
