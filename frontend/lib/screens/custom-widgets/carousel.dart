import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../theme.dart';

class CustomCarousel extends StatelessWidget {
<<<<<<< HEAD
  final List<Map<String, dynamic>> items;
=======
  final List<Map<String, String>> items;
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9

  const CustomCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 120,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1.0,
      ),
      items:
          items.map((item) {
            return _buildCarouselCard(
              context,
<<<<<<< HEAD
              icon: item["icon"] as IconData?,
=======
              icon: item["icon"],
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
              title: item["title"] ?? "",
              subtitle: item["subtitle"] ?? "",
            );
          }).toList(),
    );
  }

  /// 🔹 Reusable Carousel Card widget
  Widget _buildCarouselCard(
    BuildContext context, {
<<<<<<< HEAD
    IconData? icon,
=======
    String? icon,
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
    required String title,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
<<<<<<< HEAD
              Icon(icon, size: 40, color: Colors.white),
=======
              Icon(
                IconData(int.parse(icon), fontFamily: 'MaterialIcons'),
                size: 40,
                color: Colors.white, // 👈 make icon visible on gradient
              ),
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
<<<<<<< HEAD
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
=======
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ), // 👈 white for contrast
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
<<<<<<< HEAD
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
=======
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ), // 👈 softer text
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
