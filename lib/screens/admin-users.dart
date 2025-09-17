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
  final AdminService _adminService = AdminService();

  final ScrollController _scrollController = ScrollController();

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

    final users = await _adminService.getAllUsers(context, page: page);

    setState(() {
      if (append) {
        _users.addAll(users);
        _loadingMore = false;
      } else {
        _users = users;
        _loading = false;
      }

      // If API returns empty list, assume no more data
      if (users.isEmpty) _hasMore = false;
    });
  }

  Future<void> _loadMoreUsers() async {
    _currentPage++;
    await _loadUsers(page: _currentPage, append: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
            color: AppColors.primary,
            alignment: Alignment.center,
            child: FadeInDown(
              child: Text(
                "Manage Users",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                  ? const Center(child: Text("No users found"))
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        // Loader at bottom when fetching next page
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
                          "${firstname.isNotEmpty ? firstname : ''} ${lastname.isNotEmpty ? lastname : ''}"
                              .trim();

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
                            title: Text(
                              fullName.isNotEmpty ? fullName : "Unknown",
                            ),
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
