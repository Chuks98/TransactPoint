import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user-model.dart';
import '../screens/custom-widgets/snackbar.dart';

class RegisterService {
  final String baseUrl = dotenv.env['BASE_URL']!;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  final String _key = 'logged_in_user';

  /// get logged in user
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final data = await secureStorage.read(key: _key);
    if (data == null) return null;
    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Registers user and optionally sets PIN or enables biometric
  Future<void> register(
    BuildContext context,
    User user, {
    String? pin,
    bool useBiometric = false,
  }) async {
    final url = Uri.parse(
      '$baseUrl/user/register',
    ); // Backend must handle PIN if provided

    try {
      final body = {
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phoneNumber': user.phoneNumber,
      };

      // Only send password if user chose PIN
      if (pin != null && pin.isNotEmpty) {
        body['password'] = pin;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ User registered successfully: $responseData");
        showCustomSnackBar(
          context,
          responseData['message'] ?? "User registered successfully.",
        );

        // Save locally depending on choice
        if (pin != null && pin.isNotEmpty) {
          await secureStorage.write(key: 'user_pin', value: pin);
          await secureStorage.write(key: 'use_biometric', value: 'false');
        } else if (useBiometric) {
          await secureStorage.write(key: 'user_pin', value: '');
          await secureStorage.write(key: 'use_biometric', value: 'true');
        }

        // Mark user as logged in
        await secureStorage.write(key: 'is_logged_in', value: 'true');
        await secureStorage.write(
          key: 'logged_in_user',
          value: jsonEncode(user.toJson()),
        );

        // Navigate to Home (or next page)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print("❌ Failed to register user: ${response.statusCode}");
        print("Response body: $responseData");
        showCustomSnackBar(
          context,
          responseData['message'] ?? "Registration failed.",
        );
      }
    } catch (e) {
      print("🚨 Registration error: $e");
      showCustomSnackBar(context, "Registration error: $e");
    }
  }

  /// Retrieves PIN locally
  Future<String?> getPin() async => await secureStorage.read(key: 'user_pin');

  /// Retrieves biometric preference
  Future<bool> getBiometricPreference() async {
    final val = await secureStorage.read(key: 'use_biometric');
    return val == 'true';
  }

  /// Login with PIN
  Future<bool> loginWithPin(String pin) async {
    final storedPin = await secureStorage.read(key: 'user_pin');
    if (storedPin != null && storedPin == pin) {
      await secureStorage.write(key: 'is_logged_in', value: 'true');
      return true;
    }
    return false;
  }

  /// Authenticate via biometric
  Future<bool> authenticateBiometric() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      return authenticated;
    } catch (e) {
      print("Biometric auth error: $e");
      return false;
    }
  }
}
