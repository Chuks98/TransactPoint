import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../screens/custom-widgets/snackbar.dart';

class AdminService {
  final String baseUrl = dotenv.env['BASE_URL']!;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String _key = 'logged_in_admin';

  /// Admin login
  Future<bool> adminLogin(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/admin/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        showCustomSnackBar(context, "Admin login successful!");
        await secureStorage.write(key: 'is_logged_in', value: 'true');
        return true;
      } else {
        print(responseData['message']);
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  /// Get logged in admin data
  Future<Map<String, dynamic>?> getLoggedInAdmin() async {
    final data = await secureStorage.read(key: _key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  /// Check if admin is logged in
  Future<bool> isLoggedIn() async {
    final data = await secureStorage.read(key: _key);
    return data != null;
  }

  /// Logout admin
  Future<void> logoutAdmin(BuildContext context) async {
    await secureStorage.delete(key: _key);
    showCustomSnackBar(context, "Admin logged out successfully.");
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin-login',
      (route) => false,
    );
  }

  /// Fetch all users
  Future<List<dynamic>> getAllUsers(
    BuildContext context, {
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/users?page=$page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') return body['data'];
        showCustomSnackBar(context, body['message'] ?? 'Failed to fetch users');
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch users: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching users: $e');
    }
    return [];
  }

  /// Fetch all wallets
  Future<List<dynamic>> getAllWallets(
    BuildContext context, {
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/wallets?page=$page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') return body['data'];
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch wallets',
        );
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch wallets: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching wallets: $e');
    }
    return [];
  }

  /// Fetch all transactions
  Future<List<dynamic>> getAllTransactions(
    BuildContext context, {
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/transactions?page=$page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') return body['data'];
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch transactions',
        );
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching transactions: $e');
    }
    return [];
  }

  /// Fetch transactions by status
  Future<List<dynamic>> getTransactionsByStatus(
    BuildContext context,
    String status, {
    int page = 1,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/admin/transactions?status=$status&page=$page',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') return body['data'];
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch transactions',
        );
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching transactions: $e');
    }
    return [];
  }

  /// Fetch single wallet by user ID
  Future<Map<String, dynamic>> getWalletByUser(
    BuildContext context,
    String userId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/admin/wallet/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') return body;
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch wallet',
        );
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch wallet: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching wallet: $e');
    }
    return {'status': 'error', 'message': 'Failed to fetch wallet'};
  }
}
