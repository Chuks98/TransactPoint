import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/screens/custom-widgets/curved-design.dart';
import 'package:transact_point/screens/custom-widgets/date-formatter.dart';
import 'package:transact_point/screens/custom-widgets/snackbar.dart';
import 'package:transact_point/services/user-api-services.dart';
import 'dart:convert';

import '../theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final storage = const FlutterSecureStorage();
  String fullName = "";
  String phoneNumber = "";
  String userId = "";
  List<dynamic> transactions = [];
  bool _fetchingTransactions = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final rawUser = await storage.read(key: "logged_in_user");
    if (rawUser != null) {
      final data = jsonDecode(rawUser);
      setState(() {
        fullName = "${data["firstName"]} ${data["lastName"]}" ?? "";
        phoneNumber = data["phoneNumber"] ?? "";
        userId = data["id"].toString(); // 👈 store userId for API calls
      });

      // Fetch first page after loading user
      _fetchTransactions(userId);
    }
  }

  Future<void> _fetchTransactions(
    String userId, {
    bool loadMore = false,
  }) async {
    if (_fetchingTransactions) return;

    setState(() => _fetchingTransactions = true);
    try {
      final result = await RegisterService().getUserTransactions(
        userId,
        page: _currentPage,
      );

      final List newTx = result['data'] ?? [];
      final nextPageUrl = result['next_page_url'];

      setState(() {
        if (loadMore) {
          transactions.addAll(newTx);
        } else {
          transactions = newTx;
        }
        _hasMore = nextPageUrl != null;
        if (_hasMore) _currentPage++;
      });
    } catch (e) {
      showCustomSnackBar(context, "Failed to fetch transactions: $e");
    } finally {
      setState(() => _fetchingTransactions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String firstLetter =
        fullName.isNotEmpty ? fullName.trim()[0].toUpperCase() : "?";

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.zero, // 🔥 removes 20px padding at top + sides
        child: Column(
          children: [
            FadeInDown(
              child: ClipPath(
                clipper: UCurveClipper(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 0, // 👈 remove side padding here
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          firstLetter,
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phoneNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Transactions List
            BounceInLeft(
              child:
                  _fetchingTransactions
                      ? const Center(child: CircularProgressIndicator())
                      : transactions.isEmpty
                      ? const Text("No transactions yet.")
                      : Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal:
                                      12, // 👈 little margin on the sides
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ), // 👈 updated radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.primary
                                        .withOpacity(0.1),
                                    child: Icon(
                                      tx['status'] != 'successful'
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color:
                                          tx['status'] != 'successful'
                                              ? Colors.red
                                              : AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    tx['description'] ?? 'Transaction',
                                    style: textTheme.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    DateFormatter.formatDate(tx['created_at']),
                                    style: textTheme.bodySmall!.copyWith(
                                      color: AppColors.grey,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${tx['status'] != 'successful' ? '-' : '+'} ${tx['currencySign']}${tx['amount']}",
                                    style: textTheme.bodyMedium!.copyWith(
                                      color:
                                          tx['status'] != 'successful'
                                              ? Colors.red
                                              : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_hasMore)
                            TextButton(
                              onPressed: () {
                                _fetchTransactions(userId, loadMore: true);
                              },
                              child: const Text("See More"),
                            ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
