import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:transact_point/screens/custom-widgets/date-formatter.dart';
import 'package:transact_point/services/admin-api-services.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart'; // UCurveClipper

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final AdminService _adminServices = AdminService();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
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
    _fetchTransactions();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      _searchQuery = query;
      await _fetchTransactions(); // fetch with search
      setState(() => _isSearching = false);
    });
  }

  Future<void> _fetchTransactions({bool nextPage = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _adminServices.getAllTransactions(
      context,
      page: nextPage ? _page + 1 : 1,
      search: _searchQuery, // send search query
    );

    setState(() {
      _page = result['current_page'];
      _lastPage = result['last_page'];

      if (nextPage) {
        transactions.addAll(List<Map<String, dynamic>>.from(result['data']));
      } else {
        transactions = List<Map<String, dynamic>>.from(result['data']);
      }

      _applySearch(_searchQuery); // refresh filter
      _isLoading = false;
    });
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        filteredTransactions = List.from(transactions);
      } else {
        filteredTransactions =
            transactions.where((tx) {
              final fields = [
                tx['fullName']?.toString() ?? "",
                tx['phoneNumber']?.toString() ?? "",
                tx['type']?.toString() ?? "",
                tx['status']?.toString() ?? "",
                tx['country']?.toString() ?? "",
                tx['transaction_id']?.toString() ?? "",
                tx['amount']?.toString() ?? "",
              ];
              return fields.any((f) => f.toLowerCase().contains(_searchQuery));
            }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "successful":
        return Colors.green;
      case "pending":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Transaction Details"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaction ID: ${tx['transaction_id']}"),
                  Text("User: ${tx['fullName']}"),
                  if (tx['phoneNumber'] != null)
                    Text("Phone: ${tx['phoneNumber']}"),
                  Text("Type: ${tx['type']}"),
                  Text("Amount: ${tx['currencySign'] ?? '₦'} ${tx['amount']}"),
                  Text("Status: ${tx['status']}"),
                  if (tx['description'] != null)
                    Text("Description: ${tx['description']}"),
                  if (tx['biller_code'] != null)
                    Text("Biller Code: ${tx['biller_code']}"),
                  if (tx['item_code'] != null)
                    Text("Item Code: ${tx['item_code']}"),
                  Text("Country: ${tx['country']}"),
                  Text("Date: ${DateFormatter.formatDate(tx['created_at'])}"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
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
                "Transactions Overview",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search by name, phone, type, status, ID, amount...",
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

        // Transactions view
        Expanded(
          child: Column(
            children: [
              Expanded(
                child:
                    _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : filteredTransactions.isEmpty
                        ? const Center(child: Text("No transactions found"))
                        : _isGrid
                        ? _buildGridView()
                        : _buildListView(),
              ),

              // Load more button only if not searching and there are more pages
              if (!_isSearching && _page < _lastPage && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () => _fetchTransactions(nextPage: true),
                    child: const Text("Load More"),
                  ),
                ),

              if (_isLoading && transactions.isNotEmpty && !_isSearching)
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

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];
        final statusColor = _getStatusColor(tx['status']);
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          duration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: () => _showTransactionDetails(tx),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      child: Icon(Icons.receipt_long, color: statusColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tx['fullName'] ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (tx['phoneNumber'] != null)
                      Text(
                        tx['phoneNumber'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      "${tx['currencySign'] ?? '₦'} ${(double.tryParse(tx['amount'].toString()) ?? 0).toStringAsFixed(2)} • ${tx['status']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];
        final statusColor = _getStatusColor(tx['status']);
        return SlideInUp(
          delay: Duration(milliseconds: 120 * index),
          duration: const Duration(milliseconds: 450),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(Icons.receipt_long, color: statusColor),
              ),
              title: Text("${tx['fullName']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tx['phoneNumber'] != null)
                    Text(
                      tx['phoneNumber'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  Text(
                    "${tx['currencySign'] ?? '₦'} ${(double.tryParse(tx['amount'].toString()) ?? 0).toStringAsFixed(2)} • ${tx['status']}",
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTransactionDetails(tx),
            ),
          ),
        );
      },
    );
  }
}
