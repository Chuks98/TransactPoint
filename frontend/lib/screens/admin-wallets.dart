import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/services/admin-api-services.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart'; // your UCurveClipper

class AdminWalletsScreen extends StatefulWidget {
  const AdminWalletsScreen({super.key});

  @override
  State<AdminWalletsScreen> createState() => _AdminWalletsScreenState();
}

class _AdminWalletsScreenState extends State<AdminWalletsScreen> {
  final AdminService _adminServices = AdminService();
  List<Map<String, dynamic>> wallets = [];
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  bool _isGrid = false;
  String _searchQuery = "";
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      _searchQuery = query;
      await _fetchWallets(); // fetch from backend with search
      setState(() => _isSearching = false);
    });
  }

  Future<void> _fetchWallets({bool nextPage = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _adminServices.getAllWallets(
      context,
      page: nextPage ? _page + 1 : 1,
      search: _searchQuery,
    );

    setState(() {
      _page = result['current_page'];
      _lastPage = result['last_page'];
      if (nextPage) {
        wallets.addAll(List<Map<String, dynamic>>.from(result['data']));
      } else {
        wallets = List<Map<String, dynamic>>.from(result['data']);
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Curved header
        ClipPath(
          clipper: UCurveClipper(),
          child: Container(
            height: 140,
            width: double.infinity,
<<<<<<< HEAD
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
=======
            color: AppColors.primary,
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
            alignment: Alignment.center,
            child: FadeInDown(
              child: Text(
                "Accounts Overview",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search by name, phone, balance, country, currency...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Toggle buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: "List view",
                icon: Icon(
                  Icons.list,
                  color: !_isGrid ? AppColors.primary : Colors.grey,
                ),
                onPressed: () => setState(() => _isGrid = false),
              ),
              IconButton(
                tooltip: "Grid view",
                icon: Icon(
                  Icons.grid_view,
                  color: _isGrid ? AppColors.primary : Colors.grey,
                ),
                onPressed: () => setState(() => _isGrid = true),
              ),
            ],
          ),
        ),

        // Replace the bottom section inside Expanded
        Expanded(
          child: Column(
            children: [
              // List/Grid view
              Expanded(
                child:
                    _isLoading && wallets.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _isGrid
                        ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: wallets.length,
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              duration: const Duration(milliseconds: 400),
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        wallet['fullName'] ?? "Unknown",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (wallet['phoneNumber'] != null)
                                        Text(
                                          wallet['phoneNumber'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        "${wallet['currencySign']} ${(double.tryParse(wallet['balance'].toString()) ?? 0).toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: wallets.length,
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            return SlideInUp(
                              delay: Duration(milliseconds: 120 * index),
                              duration: const Duration(milliseconds: 450),
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(wallet['fullName'] ?? "Unknown"),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (wallet['phoneNumber'] != null)
                                        Text(
                                          wallet['phoneNumber'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      Text(
                                        "Balance: ${wallet['currencySign']} ${(double.tryParse(wallet['balance'].toString()) ?? 0).toStringAsFixed(2)}",
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // TODO: Navigate to wallet details
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),

              // 🔹 Show Load More button only if there are more pages
              if (_page < _lastPage && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () => _fetchWallets(nextPage: true),
                    child: const Text("Load More"),
                  ),
                ),

              // 🔹 Show centered loader only during fetching next page
              if (_isLoading && wallets.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
