import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:transact_point/models/saving-plan.dart';
=======
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
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
        await secureStorage.write(key: _key, value: 'true');

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
  Future<bool> isAdminLoggedIn() async {
    final data = await secureStorage.read(key: _key);
    return data != null;
  }

  /// Logout admin
  Future<void> logoutAdmin(BuildContext context) async {
    await secureStorage.delete(key: _key);
    showCustomSnackBar(context, "Admin logged out successfully.");
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Fetch all users
  Future<List<dynamic>> getAllUsers(
    BuildContext context, {
    int page = 1,
    String search = '',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/users?page=$page&search=$search');
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
  Future<Map<String, dynamic>> getAllWallets(
    BuildContext context, {
    int page = 1,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse(
        '$baseUrl/admin/wallets',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return {
            'data': body['data'],
            'total': body['total'],
            'current_page': body['current_page'],
            'last_page': body['last_page'],
          };
        }
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch wallets',
        );
        return {
          'data': [],
          'total': 0,
          'current_page': page,
          'last_page': page,
        };
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch wallets: ${response.statusCode}',
        );
        return {
          'data': [],
          'total': 0,
          'current_page': page,
          'last_page': page,
        };
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching wallets: $e');
      return {'data': [], 'total': 0, 'current_page': page, 'last_page': page};
    }
  }

  /// Fetch all transactions with pagination
  Future<Map<String, dynamic>> getAllTransactions(
    BuildContext context, {
    int page = 1,
    String search = "", // <-- add search
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/admin/transactions?page=$page&search=$search',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return {
            'data': body['data'],
            'total': body['total'],
            'current_page': body['current_page'],
            'last_page': body['last_page'],
          };
        }
        showCustomSnackBar(
          context,
          body['message'] ?? 'Failed to fetch transactions',
        );
        return {
          'data': [],
          'total': 0,
          'current_page': page,
          'last_page': page,
        };
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch transactions: ${response.statusCode}',
        );
        return {
          'data': [],
          'total': 0,
          'current_page': page,
          'last_page': page,
        };
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching transactions: $e');
      return {'data': [], 'total': 0, 'current_page': page, 'last_page': page};
    }
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
<<<<<<< HEAD

  // Savings Plans CRUD system
  Future<List<Plan>> getPlans(BuildContext context) async {
    try {
      final url = Uri.parse('$baseUrl/admin/get-plans');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List data = body['data'];
          return data.map((e) => Plan.fromJson(e)).toList();
        }
        showCustomSnackBar(context, body['message'] ?? 'Failed to fetch plans');
      } else {
        showCustomSnackBar(
          context,
          'Failed to fetch plans: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error fetching plans: $e');
    }
    return [];
  }

  /// Create a new plan
  Future<bool> createPlan(
    BuildContext context,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/admin/create-plan');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          showCustomSnackBar(
            context,
            res['message'] ?? 'Plan created successfully',
          );
          return true;
        }
        showCustomSnackBar(context, res['message'] ?? 'Failed to create plan');
      } else {
        showCustomSnackBar(
          context,
          'Failed to create plan: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error creating plan: $e');
    }
    return false;
  }

  /// Update existing plan
  Future<bool> updatePlan(
    BuildContext context,
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/admin/update-plan/$id');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          showCustomSnackBar(
            context,
            res['message'] ?? 'Plan updated successfully',
          );
          return true;
        }
        showCustomSnackBar(context, res['message'] ?? 'Failed to update plan');
      } else {
        showCustomSnackBar(
          context,
          'Failed to update plan: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error updating plan: $e');
    }
    return false;
  }

  /// Delete a plan
  Future<bool> deletePlan(BuildContext context, int id) async {
    try {
      final url = Uri.parse('$baseUrl/admin/delete-plan/$id');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          showCustomSnackBar(
            context,
            res['message'] ?? 'Plan deleted successfully',
          );
          return true;
        }
        showCustomSnackBar(context, res['message'] ?? 'Failed to delete plan');
      } else {
        showCustomSnackBar(
          context,
          'Failed to delete plan: ${response.statusCode}',
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error deleting plan: $e');
    }
    return false;
  }
=======
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
}
