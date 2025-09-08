import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';

class ApiService {
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
          "Failed to fetch categories. Please try again.",
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

  /// Fetch all billers
  Future<List<dynamic>> fetchBillers({String country = "NG"}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/billers?country=$country"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("Billers Response: $decoded");
        return decoded['data'] ?? []; // Flutterwave returns billers in data
      } else {
        print("Failed to fetch billers: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching billers: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchBillerItems(String billerCode) async {
    final response = await http.get(
      Uri.parse("$baseUrl/billers/$billerCode/items"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print("Biller Items Response: $decoded");
      return decoded['data'] ?? [];
    } else {
      print("Failed to fetch biller items: ${response.body}");
      return [];
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
        showCustomSnackBar(context, "Warning: ${decodedBody["message"]}");
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
      Uri.parse("$baseUrl/resolve-account"),
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
  Future<Map<String, dynamic>> transfer({
    context,
    required String accountBank,
    required String accountNumber,
    required double amount,
    String currency = "NGN",
    String narration = "Wallet Transfer",
    String? country,
    String? swiftCode,
    String? beneficiaryName,
    String? beneficiaryAddress,
    String? beneficiaryCity,
  }) async {
    final Map<String, dynamic> payload = {
      "account_bank": accountBank,
      "account_number": accountNumber,
      "amount": amount,
      "currency": currency,
      "narration": narration,
    };

    // Optional fields (only if backend supports them)
    if (country != null) payload["country"] = country;
    if (swiftCode != null) payload["swift_code"] = swiftCode;
    if (beneficiaryName != null) payload["beneficiary_name"] = beneficiaryName;
    if (beneficiaryAddress != null) {
      payload["beneficiary_address"] = beneficiaryAddress;
    }
    if (beneficiaryCity != null) payload["beneficiary_city"] = beneficiaryCity;

    final response = await http.post(
      Uri.parse("$baseUrl/transfer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    final body = json.decode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      showCustomSnackBar(context, body["message"] ?? "Transfer successful");
      return body;
    } else {
      showCustomSnackBar(context, body["message"] ?? "Transfer failed");
      return {};
    }
  }
}
