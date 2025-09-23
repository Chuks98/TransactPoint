import 'package:flutter/material.dart';
import 'package:transact_point/screens/biometric.dart';
import '../models/user-model.dart';
import '../theme.dart';
import 'package:network_info_plus/network_info_plus.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPhoneController = TextEditingController();
  final _bvnController = TextEditingController();

  bool _isLoading = false;
  String? _phoneError;
  String? _bvnError;
  bool _isFormValid = false;

  void _forwardData() {
    if (_formKey.currentState!.validate() &&
        _phoneError == null &&
        _bvnError == null) {
      setState(() {
        _isLoading = true;
      });

      User user = User(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bvn: _bvnController.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BiometricScreen(user: user)),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _localIp;
  final info = NetworkInfo();

  Future<void> getLocalIp() async {
    String? ip = await info.getWifiIP();
    setState(() {
      _localIp = ip ?? "Not connected";
    });
  }

  @override
  void initState() {
    super.initState();
    getLocalIp();

    // Watch for changes to revalidate form
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(() {
      _validateForm();
      _checkPhoneMatch(_confirmPhoneController.text);
    });
    _confirmPhoneController.addListener(() {
      _validateForm();
      _checkPhoneMatch(_confirmPhoneController.text);
    });
    _bvnController.addListener(_checkBvn);
  }

  void _checkPhoneMatch(String value) {
    setState(() {
      if (value.isNotEmpty && value != _phoneController.text.trim()) {
        _phoneError = "Phone numbers do not match";
      } else {
        _phoneError = null;
      }
    });
  }

  void _checkBvn() {
    setState(() {
      if (_bvnController.text.isNotEmpty && _bvnController.text.length != 11) {
        _bvnError = "BVN must be 11 digits";
      } else {
        _bvnError = null;
      }
      _validateForm();
    });
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _confirmPhoneController.text.isNotEmpty &&
          _phoneError == null &&
          _bvnError == null; // 👈 BVN error handled separately
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
                decoration: const InputDecoration(
                  labelText: "First Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator:
                    (value) => value!.isEmpty ? "Enter first name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value!.isEmpty ? "Enter last name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "e.g. example@mail.com",
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter email";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "e.g. 0703 445 3434",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) => value!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPhoneController,
                decoration: InputDecoration(
                  labelText: "Confirm Phone Number",
                  errorText: _phoneError,
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              /// 👇 BVN Field
              TextFormField(
                controller: _bvnController,
                decoration: InputDecoration(
                  labelText: "BVN",
                  hintText: "Enter your BVN",
                  prefixIcon: const Icon(Icons.credit_card),
                  errorText: _bvnError, // 👈 red warning for BVN
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Your BVN will be used for creating your Nigerian bank account securely.",
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed:
                        _isFormValid
                            ? _forwardData
                            : null, // 👈 only enabled if valid
                    child: const Text("Register"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
