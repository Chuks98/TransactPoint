import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transact_point/services/user-api-services.dart';
import '../screens/custom-widgets/snackbar.dart';
import './custom-widgets/login-widgets.dart'; // import the widget functions

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final RegisterService _authService = RegisterService();
  String _pin = '';
  bool _useBiometric = false;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ValueNotifier<bool> _showPin = ValueNotifier(false);
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
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
    super.dispose();
  }

  Future<void> _loadBiometricPreference() async {
    bool pref = await _authService.getBiometricPreference();
    setState(() {
      _useBiometric = pref;
    });
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });
      if (_pin.length == 6) _authenticate();
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty)
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    bool success = false;

    if (_useBiometric) {
      success = await _authService.authenticateBiometric();
      showCustomSnackBar(
        context,
        success
            ? "Biometric login successful!"
            : "Biometric authentication failed.",
      );
    } else {
      if (_pin.length != 6) {
        showCustomSnackBar(context, "PIN must be 6 digits");
        setState(() => _isLoading = false);
        return;
      }
      success = await _authService.loginWithPin(_pin);
      showCustomSnackBar(
        context,
        success ? "Login successful!" : "Invalid PIN. Try again.",
      );
      if (!success) setState(() => _pin = '');
    }

    if (success) Navigator.pushReplacementNamed(context, '/home');
    setState(() => _isLoading = false);
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
              await _authenticate();
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
                        height: 100,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Transact Point',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.cardTheme.color,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CHUKWUMA(704****391)',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child:
                  _useBiometric
                      ? biometricSection(
                        context,
                        isLoading: _isLoading,
                        onAuthenticate: _authenticate,
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
                        onAuthenticate: _authenticate,
                        onNumberPressed: _onNumberPressed,
                        onDeletePressed: _onDeletePressed,
                        showPinNotifier: _showPin, // pass it here
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap:
                    () => setState(() {
                      _useBiometric = !_useBiometric;
                      _pin = '';
                    }),
                child: Text(
                  _useBiometric
                      ? 'Login with Password'
                      : 'Login with Fingerprint',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
