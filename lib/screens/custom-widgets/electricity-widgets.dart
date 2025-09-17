import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import '../../theme.dart';

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
Widget buildElectricityUssdBanner(BuildContext context) {
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
          TextSpan(text: 'No Electricity Credit?\n'),
          TextSpan(
            text: 'Top up easily via USSD: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: '*555*meterNumber*amount#',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

final Map<String, String> electricityLogos = {
  "EKO DISCO ELECTRICITY BILLS": "assets/images/ekedc-logo.png",
  "ENUGU DISCO ELECTRICITY BILLS": "assets/images/eedc-logo.jpeg",
  "IBADAN DISCO ELECTRICITY BILLS": "assets/images/ibedc-logo.jpeg",
  "IKEJA DISCO ELECTRICITY BILLS": "assets/images/ikedc-logo.png",
  "KADUNA DISCO ELECTRICITY BILLS": "assets/images/kandco-logo.jpeg",
  "KANO DISCO ELECTRICITY BILLS": "assets/images/kedco-logo.png",
  "PORT HARCOURT DISCO ELECTRICITY BILLS": "assets/images/phedc-logo.jpeg",
  // Add more if there are other providers in the future
};

Widget meterNumberSection(
  BuildContext context, {
  required TextEditingController controller,
  required List<dynamic> electricityPlans,
  required String? selectedBillerCode,
  required ValueChanged<String?> onBillerChanged,
}) {
  // Group billers by short name or provider code
  final Map<String, dynamic> networkBillers = {};
  for (var biller in electricityPlans) {
    final name = (biller['name'] ?? "").toUpperCase();
    // You can filter specific providers if needed
    networkBillers.putIfAbsent(name, () => biller);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dropdown for selecting provider
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
                  final biller = entry.value;
                  return DropdownMenuItem<String>(
                    value: biller['biller_code'],
                    child: Image.asset(
                      electricityLogos[entry.key]!, // <-- use entry.key here
                      width: 40,
                      height: 40,
                    ),
                  );
                }).toList(),
            onChanged: onBillerChanged,
          ),
        ),

        const SizedBox(width: 12),

        // Meter Number input
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter Meter Number',
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
          size: 30,
          color: Theme.of(context).colorScheme.primary, // optional color
        ),
      ],
    ),
  );
}

Widget buildPlanGrid({
  required List<Map<String, dynamic>> plans,
  required BuildContext context,
  String? selectedItemCode,
  String? selectedAmount,
  required ValueChanged<Map<String, dynamic>> onPlanSelected,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: plans.length * 150.0, // increase per-item height
    ),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0, // lower ratio = taller item
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isSelected = plan['item_code']?.toString() == selectedItemCode;
        return GestureDetector(
          onTap: () => onPlanSelected(plan),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
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
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    plan['biller_name']?.toString() ??
                        plan['name']?.toString() ??
                        '',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₦${plan['amount']?.toString() ?? ''}",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

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
