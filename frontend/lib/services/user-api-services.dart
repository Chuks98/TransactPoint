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

  static String? userId;
  static String? firstName;
  static String? lastName;
  static String? phoneNumber;
  static String? userFullName;

  /// Load stored user data
  Future<void> loadUserData() async {
    try {
      String? userJson = await secureStorage.read(key: "logged_in_user");
      if (userJson == null) return;

      final userMap = jsonDecode(userJson);
      userId = userMap['id']?.toString();
      firstName = userMap['firstName'] ?? "";
      lastName = userMap['lastName'] ?? "";
      phoneNumber = userMap['phoneNumber'] ?? "";
      userFullName = "$firstName $lastName".trim();
    } catch (e) {
      print("🚨 loadUserData error: $e");
    }
  }

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
        'email': user.email, // 👈 Added email
        'phoneNumber': user.phoneNumber,
        'bvn': user.bvn,
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

        // Extract data
        final userData = responseData['user'] ?? {};
        final vaData = responseData['virtualAccount'] ?? {};

        // Merge into one JSON
        final enrichedUser = {
          ...userData,
          'account_name': vaData['account_name'],
          'account_number': vaData['account_number'],
          'bank_name': vaData['bank_name'],
          'country': vaData['country'],
          'currency_sign': vaData['currency_sign'],
        };

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
          value: jsonEncode(enrichedUser),
        );

        // Navigate to Home (or next page)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print("❌ Failed to register user: $responseData");
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
  Future<bool> loginWithPin(BuildContext context, String pin) async {
    try {
      // Step 1: Get the user's phone number from secure storage
      final userJson = await secureStorage.read(key: 'logged_in_user');
      if (userJson == null) {
        showCustomSnackBar(
          context,
          'No user found. Please register or login normally.',
        );
        return false;
      }

      final userData = jsonDecode(userJson);
      final phoneNumber = userData['phoneNumber'];
      if (phoneNumber == null) {
        showCustomSnackBar(context, 'User phone number missing.');
        return false;
      }

      // Step 2: Send to backend for verification
      final url = Uri.parse('$baseUrl/user/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'password': pin}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Step 3: Store login status and updated user info
        await secureStorage.write(key: 'is_logged_in', value: 'true');
        await secureStorage.write(
          key: 'logged_in_user',
          value: jsonEncode(responseData['data']),
        );
        showCustomSnackBar(context, responseData['message']);

        return true;
      } else {
        showCustomSnackBar(context, responseData['message'] ?? 'Login failed.');
        return false;
      }
    } catch (e) {
      print("🚨 Login error: $e");
      showCustomSnackBar(context, 'Login failed: $e');
      return false;
    }
  }

  /// Login normally with phone number and PIN
  Future<bool> loginNormally(
    BuildContext context,
    String phoneNumber,
    String pin,
  ) async {
    try {
      // Step 1: Send phone + pin directly to backend
      final url = Uri.parse('$baseUrl/user/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'password': pin}),
      );

      final responseData = jsonDecode(response.body);

      // Step 2: Handle response
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Store login status and user info
        await secureStorage.write(key: 'is_logged_in', value: 'true');
        await secureStorage.write(
          key: 'logged_in_user',
          value: jsonEncode(responseData['data']),
        );

        showCustomSnackBar(context, responseData['message']);
        return true;
      } else {
        showCustomSnackBar(context, responseData['message'] ?? 'Login failed.');
        return false;
      }
    } catch (e) {
      print("🚨 LoginNormally error: $e");
      showCustomSnackBar(context, 'Login failed: $e');
      return false;
    }
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

  /// Logs out user and clears secure storage, then redirects to login page
  Future<void> logout(BuildContext context) async {
    try {
      // Delete specific keys
      await secureStorage.delete(key: 'is_logged_in');

      // If you want a complete wipe, uncomment this:
      // await secureStorage.deleteAll();

      print("✅ User logged out successfully");

      // Redirect to login page and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print("🚨 Logout error: $e");
      showCustomSnackBar(context, "Logout failed: $e");
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final value = await secureStorage.read(key: 'is_logged_in');
    return value == 'true';
  }

  Future<Map<String, dynamic>> getWallet(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/user/get-wallet/$userId');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);
      return responseData; // {status: 'success', data: {...}} or {status: 'error', message: '...'}
    } catch (e) {
      print("🚨 getWallet error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Create wallet
  Future<Map<String, dynamic>> createWallet(
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/user/create-wallet');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);
      return responseData; // {status: 'success', data: {...}} or {status: 'error', message: '...'}
    } catch (e) {
      print("🚨 createWallet error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ✅ Update Wallet / Account
  Future<Map<String, dynamic>> updateAccount({
    required String userId,
    required String country,
    required String currency,
    required String currencySign,
    required String code,
    required String amount,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/update-account');
      final payload = {
        'user_id': userId,
        'country': country,
        'currency': currency,
        'currencySign': currencySign,
        'code': code,
        'amount': amount,
      };

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);
      return responseData; // {status: 'success', data: {...}} or {status: 'error', message: '...'}
    } catch (e) {
      print("🚨 updateAccount error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Fetch recent transactions - last 10
  Future<List<dynamic>> getUserRecentTransactions(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/user/recent-transactions/$userId');
      print("📡 Fetching last 10 transactions for user $userId from $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          print(
            "✅ Transactions fetched successfully (${body['data'].length} items)",
          );
          return body['data'];
        } else {
          print("⚠️ API responded with failure: ${body['message'] ?? body}");
        }
      } else {
        print("❌ Failed with status: ${response.statusCode}");
      }
    } catch (e, stacktrace) {
      print("🔥 Error fetching transactions: $e");
      print(stacktrace);
    }
    return [];
  }

  // ✅ Fetch user transactions
  Future<Map<String, dynamic>> getUserTransactions(
    String userId, {
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/transactions/$userId?page=$page');
      print(
        "📡 Fetching page $page of transactions for user $userId from $url",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          print(
            "✅ Page $page fetched with ${body['data']['data'].length} items",
          );
          return body['data'];
        } else {
          print("⚠️ API responded with failure: ${body['message'] ?? body}");
        }
      } else {
        print("❌ Failed with status: ${response.statusCode}");
      }
    } catch (e, stacktrace) {
      print("🔥 Error fetching transactions: $e");
      print(stacktrace);
    }
    return {"data": [], "current_page": page, "next_page_url": null};
  }
}
