import 'package:flutter/material.dart';
import 'package:transact_point/screens/biometric.dart';
import '../models/user-model.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _phoneError;

  void _forwardData() {
    if (_formKey.currentState!.validate() && _phoneError == null) {
      setState(() {
        _isLoading = true;
      });

      User user = User(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      // Pass user to BiometricScreen instead of registering yet
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BiometricScreen(user: user)),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkPhoneMatch(String value) {
    setState(() {
      if (value != _phoneController.text.trim()) {
        _phoneError = "Phone numbers do not match";
      } else {
        _phoneError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
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
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator:
                    (value) => value!.isEmpty ? "Enter first name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) => value!.isEmpty ? "Enter last name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "e.g. +1 234 567 8900",
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) => value!.isEmpty ? "Enter phone number" : null,
                onChanged: _checkPhoneMatch,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPhoneController,
                decoration: InputDecoration(
                  labelText: "Confirm Phone Number",
                  hintText: "e.g. +1 234 567 8900",
                  errorText: _phoneError,
                ),
                keyboardType: TextInputType.phone,
                onChanged: _checkPhoneMatch,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _forwardData,
                    child: const Text("Register"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
