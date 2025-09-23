import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart'; // for a modern text look
import 'package:animate_do/animate_do.dart'; // for bouncing animations
import 'package:transact_point/screens/custom-widgets/confirm-dialog.dart';
import 'package:transact_point/screens/custom-widgets/curved-design.dart';
import '../services/user-api-services.dart';
import 'dart:convert';

import '../theme.dart'; // make sure this is imported

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RegisterService _authService = RegisterService();
  final storage = const FlutterSecureStorage();
  String fullName = "";
  String phoneNumber = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final rawUser = await storage.read(key: "logged_in_user");
    if (rawUser != null) {
      final data = jsonDecode(rawUser);
      setState(() {
        fullName = data["firstName"] + ' ' + data["lastName"] ?? "";
        phoneNumber = data["phoneNumber"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String firstLetter =
        fullName.isNotEmpty ? fullName.trim()[0].toUpperCase() : "?";

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Profile Header
            FadeInDown(
              child: ClipPath(
                clipper: UCurveClipper(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 0,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          firstLetter,
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phoneNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Options List
            BounceInLeft(
              child: _buildOptionTile(
                context,
                icon: Icons.settings,
                title: "My Account",
                onTap: () {
                  Navigator.pushNamed(context, '/wallet');
                },
              ),
            ),
            BounceInLeft(
              child: _buildOptionTile(
                context,
                icon: Icons.settings,
                title: "Account Settings",
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
            BounceInLeft(
              child: _buildOptionTile(
                context,
                icon: Icons.security,
                title: "Privacy",
                onTap: () {
                  Navigator.pushNamed(context, '/privacy');
                },
              ),
            ),
            BounceInLeft(
              child: _buildOptionTile(
                context,
                icon: Icons.notifications,
                title: "Notifications",
                onTap: () {},
              ),
            ),
            BounceInLeft(
              child: _buildOptionTile(
                context,
                icon: Icons.logout,
                title: "Logout",
                iconColor: Colors.red,
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => ConfirmDialog(
                          title: "Logout?",
                          content: const [
                            Text("Are you sure you want to log out?"),
                          ],
                          confirmText: "Logout",
                          cancelText: "Cancel",
                          onConfirm: () {
                            Navigator.of(ctx).pop(); // close dialog
                            _authService.logout(context);
                          },
                          onCancel: () => Navigator.of(ctx).pop(),
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
