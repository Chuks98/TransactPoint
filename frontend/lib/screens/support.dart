import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/screens/custom-widgets/support-and-privacy-widgets.dart';
import '../theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                "Welcome to Transact Point",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 300),
              child: Text(
                "Transact Point makes it simple to send and receive money across the globe, "
                "with support for international bank transfers and multiple currencies.",
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: buildSupportBanner(context),
            ),

            const SizedBox(height: 24),

            // Section 1
            SlideInRight(
              delay: const Duration(milliseconds: 600),
              child: _buildSection(
                context,
                title: "🌍 What You Can Do",
                points: [
                  "Send money internationally with just a few details.",
                  "Receive payments directly into your local or international bank account.",
                  "Support for multiple currencies including USD, EUR, GBP, NGN, KRW and more.",
                  "Track your transfers in real time.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 2
            SlideInLeft(
              delay: const Duration(milliseconds: 800),
              child: _buildSection(
                context,
                title: "🏦 Bank Details You’ll Need",
                points: [
                  "Account Holder’s Name (must match the bank account).",
                  "Bank Name & Branch.",
                  "Account Number or IBAN (depending on the country).",
                  "SWIFT/BIC code (for international transfers).",
                  "Routing Number (for US banks only).",
                  "Bank Address (sometimes required by certain banks).",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 3
            SlideInRight(
              delay: const Duration(milliseconds: 1000),
              child: _buildSection(
                context,
                title: "💡 Tips for a Smooth Transfer",
                points: [
                  "Always double-check account numbers and SWIFT codes before sending.",
                  "If your recipient does not have a USD account, their bank will convert "
                      "the funds into the local currency automatically.",
                  "Some banks (especially outside Africa) require full branch addresses.",
                  "Transfers may take 1–3 business days depending on the destination country.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 4
            SlideInLeft(
              delay: const Duration(milliseconds: 1200),
              child: _buildSection(
                context,
                title: "📱 Bill Payments (Nigeria Only)",
                points: [
                  "Buy Airtime for all major networks instantly.",
                  "Top up Data bundles with just a few taps.",
                  "Pay Cable TV subscriptions (DSTV, GOTV, Startimes, etc.).",
                  "Settle Electricity bills conveniently from your wallet.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 5
            SlideInRight(
              delay: const Duration(milliseconds: 1400),
              child: _buildSection(
                context,
                title: "📞 Need Help?",
                points: [
                  "Check the FAQ section inside the app.",
                  "Contact our support team directly through the in-app chat or email.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 1600),
              child: Text(
                "📧 Contact Us",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            BounceInUp(
              delay: const Duration(milliseconds: 1800),
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "support@transactpoint.com",
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "+1 (424) 245-0215",
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> points,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "• ",
                  style: TextStyle(fontSize: 16, color: AppColors.primary),
                ),
                Expanded(child: Text(p, style: textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
