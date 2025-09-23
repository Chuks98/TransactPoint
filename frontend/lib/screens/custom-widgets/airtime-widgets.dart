import 'package:flutter/material.dart';
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

// Map biller names to logos
final Map<String, String> billerLogos = {
  "MTN": "assets/images/mtn-logo.png",
  "AIRTEL": "assets/images/airtel-logo.png",
  "GLO": "assets/images/glo-logo.jpeg",
  "9MOBILE": "assets/images/9mobile-logo.jpeg",
};

Widget phoneNumberSection(
  BuildContext context, {
  required TextEditingController controller,
  required List<dynamic> airtimeBillers,
  required String? selectedBillerCode,
  required ValueChanged<String?> onBillerChanged,
}) {
  // Group billers by network so we have one per network
  final Map<String, dynamic> networkBillers = {};
  for (var biller in airtimeBillers) {
    final name = (biller['name'] ?? "").toUpperCase();
    for (var key in billerLogos.keys) {
      if (name.contains(key)) {
        networkBillers.putIfAbsent(key, () => biller);
      }
    }
  }

  final validValues = networkBillers.keys.toList();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dropdown with one item per network
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            value: selectedBillerCode,
            items:
                networkBillers.entries.map<DropdownMenuItem<String>>((entry) {
                  final networkName = entry.key;
                  final biller = entry.value;
                  return DropdownMenuItem<String>(
                    value: biller['biller_code'], // ✅ store the biller code
                    child: Image.asset(
                      billerLogos[networkName]!,
                      width: 40,
                      height: 40,
                    ),
                  );
                }).toList(),
            onChanged: onBillerChanged,
          ),
        ),

        // Phone number input
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter phone number',
              border: InputBorder.none,
            ),
            style: Theme.of(
              context,
            ).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(width: 8),

        Icon(
          Icons.account_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
      ],
    ),
  );
}

/// USSD Banner
Widget ussdBanner(BuildContext context) {
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
          TextSpan(text: 'Low on Airtime?\n'),
          TextSpan(
            text: 'Simply Dial ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: '*955*3*amount#',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

/// Top-up Options
Widget topUpSection(
  BuildContext context,
  List<Map<String, dynamic>> topUpOptions,
  int? selectedTopUpAmount,
  void Function(int) onTopUpSelected,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Top up',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: topUpOptions.length,
        itemBuilder: (context, index) {
          final option = topUpOptions[index];
          final isSelected = selectedTopUpAmount == option['amount'];

          return InkWell(
            onTap: () => onTopUpSelected(option['amount']),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(8),
                border:
                    isSelected
                        ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₦${option['cashback']} Cashback',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${option['amount']}',
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// Custom Amount + Pay Button
Widget customAmountSection(
  BuildContext context,
  TextEditingController controller,
  VoidCallback clearSelection,
  VoidCallback onBuy, // 👈 new parameter
) {
  return Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            prefixText: '₦ ',
            hintText: "₦50 - 500,000",
          ),
          onTap: () {
            if (controller.text == "50-500,000") controller.clear();
            clearSelection();
          },
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(
          onPressed: onBuy, // 👈 trigger the callback
          child: const Text('Buy'),
        ),
      ),
    ],
  );
}

/// Airtime Service Section
Widget airtimeServiceSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Airtime Service',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.dialpad, color: AppColors.grey),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USSD enquiry',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Check phone balance and more',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    ],
  );
}
