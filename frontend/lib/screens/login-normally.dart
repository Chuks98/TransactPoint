import 'package:flutter/material.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import '../services/user-api-services.dart'; // 👈 make sure this path is correct

class LoginNormallyScreen extends StatefulWidget {
  @override
  _LoginNormallyScreenState createState() => _LoginNormallyScreenState();
}

class _LoginNormallyScreenState extends State<LoginNormallyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePin = true; // 👈 toggle state
  final _registerService = RegisterService();

  Future<void> _loginNormally() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _registerService.loginNormally(
          context,
          _phoneController.text.trim(),
          _pinController.text.trim(),
        );

        // Navigate to home/dashboard after success
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        showCustomSnackBar(context, "Login failed: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // 👇 Listen to PIN changes
    _pinController.addListener(() {
      if (_pinController.text.length == 6) {
        _loginNormally(); // auto-submit
        FocusScope.of(context).unfocus(); // dismiss keyboard
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Normally"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "e.g. +1 234 567 8900",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) => value!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pinController,
                obscureText: _obscurePin,
                maxLength: 6, // 👈 restrict to 6 digits
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "PIN",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePin = !_obscurePin);
                    },
                  ),
                ),
                validator:
                    (value) => value!.isEmpty ? "Enter your 6-digit PIN" : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _loginNormally,
                    child: const Text("Login"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
