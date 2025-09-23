import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/screens/custom-widgets/support-and-privacy-widgets.dart';
import '../theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                "Your Privacy Matters",
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
                "This Privacy Policy explains how Transact Point collects, uses, "
                "and protects your personal information.",
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: buildPrivacyPolicyBanner(context),
            ),

            const SizedBox(height: 24),
            SlideInRight(
              delay: const Duration(milliseconds: 600),
              child: _buildSection(
                context,
                title: "1️⃣ Information We Collect",
                points: [
                  "Personal information you provide when using the app.",
                  "Transaction history and payment details.",
                  "Device and usage data for improving our services.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            SlideInLeft(
              delay: const Duration(milliseconds: 800),
              child: _buildSection(
                context,
                title: "2️⃣ How We Use Your Information",
                points: [
                  "To process transactions and payments.",
                  "To communicate important updates and offers.",
                  "To improve app functionality and user experience.",
                  "To comply with legal and regulatory obligations.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            SlideInRight(
              delay: const Duration(milliseconds: 1000),
              child: _buildSection(
                context,
                title: "3️⃣ Data Protection",
                points: [
                  "We implement security measures to protect your data.",
                  "We do not sell your personal information to third parties.",
                  "Access to your data is limited to authorized personnel.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            SlideInLeft(
              delay: const Duration(milliseconds: 1200),
              child: _buildSection(
                context,
                title: "4️⃣ Your Rights",
                points: [
                  "You can request access to your personal data.",
                  "You can request corrections or deletions of your data.",
                  "You can opt-out of marketing communications at any time.",
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            FadeInUp(
              delay: const Duration(milliseconds: 1400),
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
              delay: const Duration(milliseconds: 1600),
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
                              "privacy@transactpoint.com",
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
