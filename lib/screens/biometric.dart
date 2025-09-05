import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transact_point/services/user-api-services.dart';
import '../models/user-model.dart';
import '../screens/custom-widgets/snackbar.dart';

class BiometricScreen extends StatefulWidget {
  final User user;

  const BiometricScreen({Key? key, required this.user}) : super(key: key);

  @override
  _BiometricScreenState createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _useBiometric = false;
  final RegisterService _registerService = RegisterService();
  bool _isLoading = false;

  Future<void> _authenticateBiometric() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to secure your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        showCustomSnackBar(context, "Biometric authentication enabled!");
      }
    } catch (e) {
      showCustomSnackBar(context, "Error enabling biometric: $e");
    }
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });

    String? pin =
        _pinController.text.trim().isEmpty ? null : _pinController.text.trim();

    if (pin != null && pin.length != 4) {
      showCustomSnackBar(context, "PIN must be 4 digits");
      setState(() => _isLoading = false);
      return;
    }

    // If user chose biometric, PIN is null
    if (_useBiometric) pin = null;

    // Call single registration request with PIN or biometric
    await _registerService.register(
      context,
      widget.user,
      pin: pin,
      useBiometric: _useBiometric,
    );

    // If biometric selected, trigger auth
    if (_useBiometric) {
      await _authenticateBiometric();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set up PIN or Biometric")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Choose how to secure your account for ${widget.user.phoneNumber}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: "Enter 4-digit PIN (optional if using biometric)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _useBiometric,
                  onChanged: (val) {
                    setState(() {
                      _useBiometric = val ?? false;
                      if (_useBiometric)
                        _pinController.clear(); // clear PIN if biometric chosen
                    });
                  },
                ),
                const Text("Enable fingerprint authentication"),
              ],
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _completeRegistration,
                  child: const Text("Complete Registration"),
                ),
          ],
        ),
      ),
    );
  }
}
