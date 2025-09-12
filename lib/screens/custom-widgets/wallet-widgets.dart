import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/services/flutterwave-api-services.dart';
import '../../theme.dart';
import '../../utilities/countries.dart';

/// Action Button Widget
Widget actionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Wallet page banner
Widget buildWalletTopUpBanner(BuildContext context) {
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
            text: 'Need More Funds?\n',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: 'Top up you account instantly using '),
          TextSpan(
            text: 'Bank Transfer, Card or USSD.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

// Wallet balance and currency conversion
class WalletBalanceWidget extends StatefulWidget {
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;
  final String amount; // e.g. "1250.75"
  final String currency; // e.g. "USD"
  final String currencySign; // e.g. "$"

  const WalletBalanceWidget({
    super.key,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
    required this.amount,
    required this.currency,
    required this.currencySign,
  });

  @override
  State<WalletBalanceWidget> createState() => _WalletBalanceWidgetState();
}

class _WalletBalanceWidgetState extends State<WalletBalanceWidget> {
  String? _convertedAmount;
  String? _targetCurrency; // default conversion
  String? _rate;
  bool _loading = false;

  Future<void> _convertBalance() async {
    setState(() {
      _loading = true;
      _convertedAmount = null;
    });
    if (_targetCurrency == null) {
      showCustomSnackBar(context, "Please select a currency to convert to.");
      setState(() => _loading = false);
      return;
    }

    if (double.tryParse(widget.amount) == null ||
        double.parse(widget.amount) <= 0) {
      showCustomSnackBar(
        context,
        "Invalid amount. Balance must be greater than 0.",
      );
      setState(() => _loading = false);
      return;
    }

    final ApiService apiService = ApiService();
    final data = await apiService.convertBalance(
      context: context,
      amount: widget.amount,
      fromCurrency: widget.currency,
      toCurrency: _targetCurrency!,
    );

    if (data != null && data["success"] == true) {
      setState(() {
        _convertedAmount =
            "${getCurrencySign(_targetCurrency!)} ${data["converted_amount"].toStringAsFixed(2)}";
        _rate = data["rate"].toString();
      });
    }

    setState(() {
      _loading = false;
    });
  }

  String getCurrencySign(String code) {
    final country = countryList.firstWhere(
      (c) => c["currency"] == code,
      orElse: () => {"currency_sign": ""},
    );
    return country["currency_sign"];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Balance",
              style: textTheme.bodyMedium!.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 8),

            // Balance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isBalanceVisible
                      ? "${widget.currencySign} ${widget.amount}"
                      : "${widget.currencySign} *****",
                  style: textTheme.titleLarge!.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    widget.isBalanceVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.grey,
                  ),
                  onPressed: widget.onToggleVisibility,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Currency Selector + Convert Button
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _targetCurrency,
                    hint: const Text("Select a currency"), // placeholder
                    items:
                        countryList
                            .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem<String>(
                                value: c["currency"] as String,
                                child: Text(
                                  "${c["currency"]} (${c["currency_sign"]})",
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => _targetCurrency = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _convertBalance,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text("Convert"),
                ),
              ],
            ),

            // Converted Result
            if (_convertedAmount != null) ...[
              const SizedBox(height: 10),
              Text(
                "≈ $_convertedAmount (Rate: $_rate)",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
