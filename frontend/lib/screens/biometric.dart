import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transact_point/services/user-api-services.dart';
import 'package:transact_point/theme.dart';
import '../models/user-model.dart';
import '../screens/custom-widgets/snackbar.dart';
import './custom-widgets/login-widgets.dart'; // reuse pin/biometric section widgets

class BiometricScreen extends StatefulWidget {
  final User user;

  const BiometricScreen({Key? key, required this.user}) : super(key: key);

  @override
  _BiometricScreenState createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen>
    with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  final _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  final RegisterService _registerService = RegisterService();
  String _pin = '';

  bool _useBiometric = false;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ValueNotifier<bool> _showPin = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });
      if (_pin.length == 6) _authenticateBiometric();
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty)
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _authenticateBiometric() async {
    setState(() => _isLoading = true);
    bool success = false;

    try {
      if (_useBiometric) {
        // 🔑 Biometric flow
        final loggedInUser = await _registerService.getLoggedInUser();
        final firstTimeUser = loggedInUser == null;

        if (firstTimeUser) {
          // First-time biometric registration
          success = await _registerService.authenticateBiometric();
          if (success) {
            await _registerService.register(
              context,
              widget.user,
              useBiometric: true,
            );
          }
        } else {
          // Returning biometric login
          success = await _registerService.authenticateBiometric();
          if (success) {
            await _registerService.secureStorage.write(
              key: 'is_logged_in',
              value: 'true',
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        }

        showCustomSnackBar(
          context,
          success
              ? "Biometric authentication successful!"
              : "Biometric authentication failed.",
        );
      } else {
        if (!RegExp(r'^\d{6}$').hasMatch(_pin)) {
          showCustomSnackBar(context, _pin);
          showCustomSnackBar(context, "PIN must be exactly 6 digits");
          setState(() => _isLoading = false);
          return;
        }

        final loggedInUser = await _registerService.getLoggedInUser();
        final firstTimeUser = loggedInUser == null;

        if (firstTimeUser) {
          // First-time PIN registration
          await _registerService.register(
            context,
            widget.user,
            pin: _pin,
            useBiometric: false,
          );
        } else {
          await storage.deleteAll();
        }
      }
    } catch (e) {
      showCustomSnackBar(context, "Authentication error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showFingerprintBottomSheet(BuildContext context) async {
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      showCustomSnackBar(context, "Finger print device not available");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);

        Future.microtask(() async {
          try {
            bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Scan your fingerprint to login',
              options: const AuthenticationOptions(
                biometricOnly: true,
                stickyAuth: true,
              ),
            );

            if (didAuthenticate) {
              Navigator.pop(context);
              await _authenticateBiometric();
            } else {
              Navigator.pop(context);
              showCustomSnackBar(context, "Fingerprint not recognized");
            }
          } catch (e) {
            Navigator.pop(context);
            showCustomSnackBar(context, "Biometric error: $e");
          }
        });

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Place your finger on the sensor',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);

    String? pin =
        _pinController.text.trim().isEmpty ? null : _pinController.text.trim();

    if (pin != null && pin.length != 6) {
      showCustomSnackBar(context, "PIN must be 6 digits");
      setState(() => _isLoading = false);
      return;
    }

    if (_useBiometric) pin = null;

    // Register with PIN or biometric
    await _registerService.register(
      context,
      widget.user,
      pin: pin,
      useBiometric: _useBiometric,
    );

    if (_useBiometric) {
      await _authenticateBiometric();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text("Secure Your Account")),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Header Section
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.security,
                      size: 50,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Hi ${widget.user.firstName},",
                      style: theme.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Secure your account",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Main Section
            Expanded(
              flex: 3,
              child:
                  _useBiometric
                      ? biometricSection(
                        context,
                        isLoading: _isLoading,
                        onAuthenticate: _completeRegistration,
                        pulseAnimation: _pulseAnimation,
                        showFingerprintBottomSheet:
                            () =>
                                Future.delayed(Duration(milliseconds: 300), () {
                                  _showFingerprintBottomSheet(context);
                                }),
                      )
                      : pinSection(
                        context,
                        pin: _pin,
                        isLoading: _isLoading,
                        onAuthenticate: _authenticateBiometric,
                        onNumberPressed: _onNumberPressed,
                        onDeletePressed: _onDeletePressed,
                        showPinNotifier: _showPin, // pass it here
                      ),
            ),

            // 🔹 Toggle Section
            // Padding(
            //   padding: const EdgeInsets.all(20),
            //   child: switchLoginModeTextForRegistration(
            //     context,
            //     useBiometric: _useBiometric,
            //     onTap:
            //         () => setState(() {
            //           _useBiometric = !_useBiometric;
            //           _pinController.clear();
            //         }),
            //   ),
            // ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
