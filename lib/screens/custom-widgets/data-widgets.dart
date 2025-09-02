import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import '../../theme.dart';

/// Promo Banner
Widget buildPromoBanner() {
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

/// USSD Banner
Widget buildUssdBanner(BuildContext context) {
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
          TextSpan(text: 'Low on Data?\n'),
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

/// Phone Number Input
final Map<String, String> billerLogos = {
  "MTN": "assets/images/mtn-logo.png",
  "AIRTEL": "assets/images/airtel-logo.png",
  "GLO": "assets/images/glo-logo.jpeg",
  "9MOBILE": "assets/images/9mobile-logo.jpeg",
};

Widget phoneNumberSection(
  BuildContext context, {
  required TextEditingController controller,
  required List<dynamic> dataPlans,
  required String? selectedBillerCode,
  required ValueChanged<String?> onBillerChanged,
}) {
  // Group billers by network so we have one per network
  final Map<String, dynamic> networkBillers = {};
  for (var biller in dataPlans) {
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

/// Category Selector
Widget buildCategorySelector({
  required List<String> categories,
  required String selectedCategory,
  required Function(String) onCategorySelected,
  required BuildContext context,
}) {
  return SizedBox(
    height: 40,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory == category;

        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Plan Grid
Widget buildPlanGrid(
  List<Map<String, dynamic>> plans,
  BuildContext context, {
  required void Function(Map<String, dynamic> selectedPlan) onPlanSelected,
  String? selectedItemCode,
  String? selectedAmount,
}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
    ),
    itemCount: plans.length,
    itemBuilder: (context, index) {
      final plan = plans[index];

      // ✅ Check selection inside itemBuilder
      final isSelected =
          selectedItemCode != null &&
          plan['item_code']?.toString() == selectedItemCode;

      return InkWell(
        onTap: () {
          onPlanSelected(plan); // notify parent of selection
          showCustomSnackBar(context, "Selected: ${plan['biller_name']}");
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          height: 180,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).cardTheme.color,
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
              Flexible(
                child: Text(
                  plan["biller_name"],
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  "₦${plan["amount"]}",
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Data buy button
Widget buildBuyButton({
  required BuildContext context,
  required bool isEnabled,
  required bool isLoading,
  required VoidCallback onPressed,
  String text = "Buy Now!",
}) {
  return ElevatedButton(
    onPressed: isEnabled && !isLoading ? onPressed : null,
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child:
        isLoading
            ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
            : Text(text, style: const TextStyle(fontSize: 16)),
  );
}
