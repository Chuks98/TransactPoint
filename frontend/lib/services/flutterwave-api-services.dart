import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';

class ApiService {
  final storage = const FlutterSecureStorage();
  final String baseUrl = dotenv.env['BASE_URL']!;

  // Fetch bill categories (AIRTIME, DATA, POWER, CABLETV, etc.)
  Future<Map<String, dynamic>> fetchBillCategories(context) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bill-categories"));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("Bill Categories Response: $decoded");

        showCustomSnackBar(context, "Categories loaded successfully ✅");

        return decoded['data'] ?? {};
      } else {
        print("Failed to fetch categories: ${response.body}");
        showCustomSnackBar(
          context,
          "Failed to fetch categories. Please ensure you have internet connection.",
        );
        return {};
      }
    } catch (e) {
      print("Exception in fetchBillCategories: $e");
      showCustomSnackBar(context, "Error fetching categories: $e");
      return {};
    }
  }

  // Fetch billers by category and group by network for Airtime and Data
  Future<Map<String, List<dynamic>>> fetchBillersByCategory(
    String category,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/billers-by-category?category=$category&country=NG"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> billers = decoded['data'] ?? [];

        // Define networks for grouping
        final networks = ["MTN", "AIRTEL", "GLO", "9MOBILE"];

        if (category.toLowerCase() == 'airtime' ||
            category.toLowerCase() == 'data') {
          // Filter only NG networks
          final filtered =
              billers.where((b) {
                final name = (b['name'] ?? "").toUpperCase();
                return b['country'] == "NG" &&
                    networks.any((net) => name.contains(net));
              }).toList();

          // Group by network
          final Map<String, List<dynamic>> grouped = {
            for (var net in networks) net: [],
          };

          for (var b in filtered) {
            final name = (b['name'] ?? "").toUpperCase();
            for (var net in networks) {
              if (name.contains(net)) {
                grouped[net]!.add(b);
                break; // Stop after first match
              }
            }
          }

          print("Grouped $category billers: $grouped");
          return grouped;
        } else {
          return {"all": billers};
        }
      } else {
        print("Failed to fetch billers by category: ${response.body}");
        return {};
      }
    } catch (e) {
      print("Exception in fetchBillersByCategory: $e");
      return {};
    }
  }

  // Fetch available mobile networks (MTN, Airtel, Glo, 9mobile, etc.)
  Future<List<dynamic>> fetchMobileNetworks(context) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/mobile-networks"));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["data"]; // your Laravel controller just returns Flutterwave’s response
      } else {
        showCustomSnackBar(context, "Failed to load mobile networks");
        print("Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      showCustomSnackBar(context, "Exception in fetchMobileNetworks: $e");
      print("Exception in fetchMobileNetworks: $e");
      return [];
    }
  }

  // Purchase Airtime
  Future<Map<String, dynamic>> purchaseAirtime({
    required context,
    required String id,
    required String phone,
    required int amount,
    required String billerCode,
    required String itemCode,
    String country = "NG",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/purchase-airtime"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "phone": phone,
          "amount": amount,
          "biller_code": billerCode,
          "item_code": itemCode,
          "country": country,
        }),
      );

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          "Airtime purchase successful! Ref: ${decodedBody["data"]["reference"]}",
        );
        return decodedBody;
      } else if (response.statusCode == 500) {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else if (response.statusCode == 400) {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        return {};
      }
    } catch (e) {
      showCustomSnackBar(context, "An error occurred");
      print("Exception in purchaseAirtime: $e");
      return {};
    }
  }

  // Purchase Data
  Future<Map<String, dynamic>> purchaseData({
    required context,
    required String id,
    required String phone,
    required String billerCode,
    String? itemCode,
    String country = "NG",
    String? amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/purchase-data"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "phone": phone,
          "biller_code": billerCode,
          "item_code": itemCode,
          "country": country,
          "amount": amount,
        }),
      );

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          "Data purchase successful! Ref: ${decodedBody["data"]["reference"]}",
        );
        return decodedBody;
      } else if (response.statusCode == 500) {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else if (response.statusCode == 400) {
        showCustomSnackBar(context, "Warning: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        return {};
      }
    } catch (e) {
      showCustomSnackBar(context, "An error occurred");
      print("Exception in purchaseData: $e");
      return {};
    }
  }

  // Cable TC Subscription
  Future<Map<String, dynamic>> purchaseCable({
    required context,
    required String id,
    required String smartCard,
    required String billerCode,
    String? itemCode,
    String country = "NG",
    String? amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/purchase-cable"), // changed endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "smartcard": smartCard, // SmartCard number instead of phone
          "biller_code": billerCode,
          "item_code": itemCode,
          "country": country,
          "amount": amount,
        }),
      );

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          "Cable subscription successful! Ref: ${decodedBody["data"]["reference"]}",
        );
        return decodedBody;
      } else if (response.statusCode == 500) {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else if (response.statusCode == 400) {
        showCustomSnackBar(context, "Warning: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        return {};
      }
    } catch (e) {
      showCustomSnackBar(context, "An error occurred");
      print("Exception in purchaseCable: $e");
      return {};
    }
  }

  // Purchase Electricity
  Future<Map<String, dynamic>> purchaseElectricity({
    required context,
    required String id,
    required String meterNumber,
    required String billerCode,
    String? itemCode,
    String country = "NG",
    String? amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/purchase-electricity"), // endpoint for electricity
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "meter_number": meterNumber, // meter number instead of smartcard
          "biller_code": billerCode,
          "item_code": itemCode,
          "country": country,
          "amount": amount,
        }),
      );

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          "Electricity purchase successful! Ref: ${decodedBody["data"]["reference"]}",
        );
        return decodedBody;
      } else if (response.statusCode == 500) {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else if (response.statusCode == 400) {
        showCustomSnackBar(context, "Warning: ${decodedBody["message"]}");
        print("Error: ${response.statusCode} - ${response.body}");
        return {};
      } else {
        showCustomSnackBar(context, "Error: ${decodedBody["message"]}");
        return {};
      }
    } catch (e) {
      showCustomSnackBar(context, "An error occurred");
      print("Exception in purchaseElectricity: $e");
      return {};
    }
  }

  /// Fetch banks for a country (local transfers)
  Future<List<Map<String, String>>?> fetchBanks(String country, context) async {
    final response = await http.get(
      Uri.parse("$baseUrl/get-banks?country=$country"),
      headers: {"Accept": "application/json"},
    );
    final body = json.decode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      showCustomSnackBar(
        context,
        body["message"] ?? "Banks loaded successfully",
      );

      final List<dynamic> bankList =
          body['data']['data']; // notice the extra ['data']
      return bankList
          .map(
            (b) => {
              "id": b['id'].toString(),
              "code": b['code'].toString(),
              "name": b['name'].toString(),
            },
          )
          .toList();
    } else {
      showCustomSnackBar(context, body["message"] ?? "Failed to load banks");
      return null;
    }
  }

  /// Resolve account name for local transfers
  Future<String?> resolveAccountName({
    context,
    required String accountNumber,
    required String bankCode,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/resolve-account-name"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "account_number": accountNumber,
        "bank_code": bankCode,
      }),
    );

    final body = json.decode(response.body);

    if (response.statusCode == 200 && body["status"] == "success") {
      return body["data"]["account_name"];
    } else {
      showCustomSnackBar(
        context,
        body["message"] ?? "Failed to resolve account name",
      );
      return null;
    }
  }

  // Initiate bank transfer
  Future<bool> transfer({
    context,
    String? accountBank,
    String? accountNumber,
    double? amount,
    String currency = "NGN",
    String? description,
    String? country,
    String? swiftCode,
    String? beneficiaryName,
    String? beneficiaryAddress,
    String? beneficiaryCity,
  }) async {
    final Map<String, dynamic> payload = {
      "account_number": accountNumber,
      "amount": amount,
      "currency": currency,
      "description": description,
    };

    // Optional fields
    if (accountBank != null) payload["account_bank"] = accountBank;
    if (country != null) payload["country"] = country;
    if (swiftCode != null) payload["swift_code"] = swiftCode;
    if (beneficiaryName != null) payload["beneficiary_name"] = beneficiaryName;
    if (beneficiaryAddress != null)
      payload["beneficiary_address"] = beneficiaryAddress;
    if (beneficiaryCity != null) payload["beneficiary_city"] = beneficiaryCity;

    // ✅ Required for INTERNATIONAL transfers
    payload["meta"] = [
      {
        "sender": "Transact Point",
        "sender_country": "NG",
        "receiver_country": country,
        "purpose": description ?? "Transfer",
      },
    ];

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/transfer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200 &&
          (body["success"] == true || body["status"] == "success")) {
        showCustomSnackBar(context, body["message"] ?? "Transfer successful");
        return true;
      } else {
        showCustomSnackBar(context, body["message"] ?? "Transfer failed");
        return false;
      }
    } catch (e) {
      showCustomSnackBar(context, "Transfer failed: $e");
      return false;
    }
  }

  /// Convert Currency (calls Laravel which proxies Flutterwave rates API)
  Future<Map<String, dynamic>?> convertBalance({
    context,
    required String amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final url = Uri.parse(
        "$baseUrl/convert?amount=$amount&from_currency=$fromCurrency&to_currency=$toCurrency",
      );

      final response = await http.get(url);
      final body = json.decode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        // ✅ Show successful conversion
        showCustomSnackBar(
          context,
          "Converted: ${body["converted_amount"]} ${toCurrency}",
        );
        return body;
      } else {
        // ❌ Handle backend or Flutterwave error
        showCustomSnackBar(context, body["message"] ?? "Conversion failed");
        return null;
      }
    } catch (e) {
      print("Conversion error: $e");
      showCustomSnackBar(context, "Conversion error: $e");
      return null;
    }
  }

  // Fund my account
  Future<Map<String, dynamic>> fundAccount({
    context,
    required String amount,
    String currency = "NGN",
    String? email,
    String? id,
    String? redirectUrl,
    String? code,
    String? currencySign,
    String? country,
  }) async {
    final url = Uri.parse("$baseUrl/fund-account");

    final body = {
      "amount": amount,
      "currency": currency,
      if (id != null) "id": id,
      if (email != null) "email": email,
      if (redirectUrl != null) "redirect_url": redirectUrl,
      if (code != null) "code": code,
      if (currencySign != null) "currencySign": currencySign,
      if (country != null) "country": country,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return data;
      } else {
        return {"status": "error", "message": data['message'] ?? "Failed"};
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // Create virtual Account
  Future<Map<String, dynamic>?> createVirtualAccount({
    context,
    required String currencyCode,
  }) async {
    try {
      final userJson = await storage.read(key: 'logged_in_user');
      if (userJson == null) {
        showCustomSnackBar(context, 'User data not found');
        return null;
      }

      final userData = jsonDecode(userJson);

      final accountName = '${userData['firstName']} ${userData['lastName']}';
      final email = userData['email'];
      final firstname = userData['firstName'];
      final lastname = userData['lastName'];
      final phoneNumber = userData['phoneNumber'];

      // Send BVN only if NGN
      String? bvn;
      if (currencyCode.toUpperCase() == 'NGN') {
        bvn = userData['bvn'];
      }

      final response = await http.post(
        Uri.parse('$baseUrl/create-virtual-account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currency_code': currencyCode,
          'account_name': accountName,
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
          'phonenumber': phoneNumber,
          if (bvn != null) 'bvn': bvn, // include only for NGN
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showCustomSnackBar(context, 'Virtual account created successfully!');
        await storage.write(key: 'logged_in_user', value: jsonEncode(data));
        return data;
      } else {
        showCustomSnackBar(
          context,
          data['error'] ?? 'Failed to create virtual account',
        );
        return null;
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error: $e');
      return null;
    }
  }
}
