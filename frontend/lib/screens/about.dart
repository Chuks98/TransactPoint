import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("About Transact Point")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
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
              duration: const Duration(milliseconds: 800),
              child: Text(
                "Transact Point is a secure and easy-to-use platform that allows you "
                "to send and receive money across the globe. With support for multiple currencies "
                "and real-time tracking, managing your transactions has never been easier.",
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),

            // Section 1
            FadeInLeft(
              duration: const Duration(milliseconds: 700),
              child: _buildSection(
                context,
                title: "🌟 Key Features",
                points: [
                  "Send money internationally with minimal details.",
                  "Receive payments directly into your local or international bank account.",
                  "Support for multiple currencies including USD, EUR, GBP, NGN, KRW, and more.",
                  "Track all your transactions in real time.",
                  "Fast and secure transfers with encrypted processing.",
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 2
            FadeInRight(
              duration: const Duration(milliseconds: 700),
              child: _buildSection(
                context,
                title: "🏆 Why Choose Us",
                points: [
                  "Trusted platform for both local and international money transfers.",
                  "User-friendly interface suitable for everyone.",
                  "24/7 customer support for any queries or assistance.",
                  "Transparent fees with no hidden charges.",
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            // Section 3 - Contact Info
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📧 Contact Us",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
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
                ],
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
