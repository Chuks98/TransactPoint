import 'package:flutter/material.dart';
import 'package:transact_point/theme.dart';
import '../services/user-api-services.dart';
import 'custom-widgets/snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _registerService = RegisterService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _statusMessage = "";
  Color _statusColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkMatch);
    _confirmController.addListener(_checkMatch);
  }

  void _checkMatch() {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() {
        _statusMessage = "";
      });
      return;
    }

    if (password == confirm) {
      setState(() {
        _statusMessage = "Pins match";
        _statusColor = AppColors.primary;
      });

      // auto-submit if both are 6 digits
      // if (password.length == 6 && confirm.length == 6) {
      //   _resetPassword();
      // }
    } else {
      setState(() {
        _statusMessage = "Pins do not match";
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmController.text) {
      showCustomSnackBar(context, "Pins do not match");
      return;
    }

    setState(() => _isLoading = true);

    final response = await _registerService.resetPassword(
      context,
      widget.email,
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response == true) {
      Navigator.pushNamed(context, '/home'); // back to login
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset PIN")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              keyboardType: TextInputType.number, // PIN entry
              maxLength: 6, // restrict to 6 digits
              decoration: InputDecoration(
                labelText: "New PIN",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Confirm PIN",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _resetPassword,
                  child: const Text("Reset PIN"),
                ),
          ],
        ),
      ),
    );
  }
}
