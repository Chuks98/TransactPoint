import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart'; // UCurveClipper

class AdminSettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const AdminSettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<AdminSettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<AdminSettingsScreen> {
  late bool _isDarkMode;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Widget buildMaterialTile({required Widget child, int delay = 0}) {
      return BounceInLeft(
        delay: Duration(milliseconds: delay),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Curved header
          ClipPath(
            clipper: UCurveClipper(),
            child: Container(
              height: 140,
              width: double.infinity,
              color: AppColors.primary,
              alignment: Alignment.center,
              child: FadeInDown(
                child: Text(
                  "Settings",
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Settings list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Dark Mode
                  buildMaterialTile(
                    delay: 100,
                    child: SwitchListTile(
                      title: Text("Dark Mode", style: textTheme.bodyLarge),
                      subtitle: Text(
                        "Enable or disable dark theme",
                        style: textTheme.bodySmall,
                      ),
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        widget.toggleTheme();
                      },
                      secondary: const Icon(Icons.brightness_6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Push Notifications
                  buildMaterialTile(
                    delay: 200,
                    child: SwitchListTile(
                      title: Text(
                        "Push Notifications",
                        style: textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        "Receive notifications from the app",
                        style: textTheme.bodySmall,
                      ),
                      value: _pushNotifications,
                      onChanged:
                          (value) => setState(() => _pushNotifications = value),
                      secondary: const Icon(Icons.notifications),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Privacy Policy
                  buildMaterialTile(
                    delay: 300,
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: Text("Privacy Policy", style: textTheme.bodyLarge),
                      subtitle: Text(
                        "Read our privacy policy",
                        style: textTheme.bodySmall,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/privacy'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // About App
                  buildMaterialTile(
                    delay: 400,
                    child: ListTile(
                      leading: const Icon(Icons.info),
                      title: Text("About App", style: textTheme.bodyLarge),
                      subtitle: Text(
                        "Version 1.0.0",
                        style: textTheme.bodySmall,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Contact Support
                  buildMaterialTile(
                    delay: 500,
                    child: ListTile(
                      leading: const Icon(Icons.contact_support),
                      title: Text(
                        "Contact Support",
                        style: textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        "Get help with the app",
                        style: textTheme.bodySmall,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/support'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
