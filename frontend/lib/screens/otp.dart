import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transact_point/screens/reset-password.dart';
import '../services/user-api-services.dart';
import 'custom-widgets/snackbar.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _registerService = RegisterService();

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      showCustomSnackBar(context, "Enter OTP");
      return;
    }
    if (_secondsRemaining <= 0) {
      showCustomSnackBar(context, "OTP expired. Request again.");
      return;
    }

    setState(() => _isLoading = true);

    final response = await _registerService.verifyOtp(
      context,
      widget.email,
      _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    final success = await _registerService.forgotPassword(
      context,
      widget.email,
    );

    setState(() => _isResending = false);

    if (success) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Enter the 6-digit code sent to ${widget.email}"),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),

            // ⏳ Countdown or Resend button
            _secondsRemaining > 0
                ? Text(
                  "Expires in $_secondsRemaining seconds",
                  style: const TextStyle(color: Colors.red),
                )
                : TextButton.icon(
                  onPressed: _isResending ? null : _resendOtp,
                  icon:
                      _isResending
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh, color: Colors.blue),
                  label: const Text(
                    "Resend OTP",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("Verify OTP"),
                ),
          ],
        ),
      ),
    );
  }
}
