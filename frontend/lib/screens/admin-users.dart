import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme.dart';
import './custom-widgets/curved-design.dart'; // your UCurveClipper
import '../services/admin-api-services.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  Timer? _debounce;
  final AdminService _adminService = AdminService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isGrid = false; // <-- toggle state

  @override
  void initState() {
    super.initState();
    _loadUsers(page: _currentPage);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          _hasMore) {
        _loadMoreUsers();
      }
    });
  }

  Future<void> _loadUsers({int page = 1, bool append = false}) async {
    if (append)
      setState(() => _loadingMore = true);
    else
      setState(() => _loading = true);

    final users = await _adminService.getAllUsers(
      context,
      page: page,
      search: _searchQuery,
    );

    setState(() {
      if (append) {
        _users.addAll(users);
        _loadingMore = false;
      } else {
        _users = users;
        _loading = false;
      }

      if (users.isEmpty) _hasMore = false;
    });
  }

  Future<void> _loadMoreUsers() async {
    _currentPage++;
    await _loadUsers(page: _currentPage, append: true);
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
        _hasMore = true;
      });
      _loadUsers(page: 1);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
            alignment: Alignment.center,
            child: FadeInDown(
              child: Text(
                "Welcome Admin",
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
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearch,
          ),
        ),

        // Toggle buttons (Grid/List)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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

        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                  ? const Center(child: Text("No users found"))
                  : _isGrid
                  ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 per row
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: _users.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user = _users[index];
                      final firstname = user['firstName'] ?? '';
                      final lastname = user['lastName'] ?? '';
                      final phone = user['phoneNumber'] ?? 'No phone';
                      final fullName =
                          "$firstname $lastname".trim().isNotEmpty
                              ? "$firstname $lastname".trim()
                              : "Unknown";

                      return FadeInRight(
                        delay: Duration(milliseconds: 100 * index),
                        duration: const Duration(milliseconds: 400),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    firstname.isNotEmpty
                                        ? firstname[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  phone,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final user = _users[index];
                      final firstname = user['firstName'] ?? '';
                      final lastname = user['lastName'] ?? '';
                      final phone = user['phoneNumber'] ?? 'No phone';
                      final fullName =
                          "$firstname $lastname".trim().isNotEmpty
                              ? "$firstname $lastname".trim()
                              : "Unknown";

                      return FadeInRight(
                        delay: Duration(milliseconds: 100 * index),
                        duration: const Duration(milliseconds: 400),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                firstname.isNotEmpty
                                    ? firstname[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(fullName),
                            subtitle: Text(phone),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                // TODO: Add actions like edit, delete
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
