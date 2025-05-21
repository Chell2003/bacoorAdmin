import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/sidebar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.people_alt_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Management',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              Text(
                                'Manage your registered users',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            filled: false,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .where('role', isNotEqualTo: 'Admin')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var users = snapshot.data!.docs;
                      
                      // Filter users based on search query
                      if (_searchQuery.isNotEmpty) {
                        users = users.where((user) {
                          final data = user.data() as Map<String, dynamic>;
                          return data['username']?.toString().toLowerCase().contains(_searchQuery) ?? false;
                        }).toList();
                      }

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0), // Consistent padding
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index].data() as Map<String, dynamic>;
                          final bool isActive = user['status'] == 'Active';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        radius: 24,
                                        backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                                            ? NetworkImage(user['photoURL'])
                                            : null,
                                        child: user['photoURL'] == null || user['photoURL'].toString().isEmpty
                                            ? Text(
                                                (user['username'] as String).substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['username'] ?? '',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user['email'] ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Colors.green.withOpacity(0.1)
                                                        : Theme.of(context).colorScheme.error.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        margin: const EdgeInsets.only(right: 6),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: isActive ? Colors.green : Theme.of(context).colorScheme.error,
                                                        ),
                                                      ),
                                                      Text(
                                                        user['status'] ?? 'Unknown',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isActive ? Colors.green : Theme.of(context).colorScheme.error,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    user['role'] ?? 'User',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.secondary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isActive ? Icons.block : Icons.check_circle,
                                              color: isActive
                                                  ? Theme.of(context).colorScheme.error
                                                  : Colors.green,
                                            ),
                                            onPressed: () => _toggleUserStatus(user),
                                            tooltip: isActive ? 'Block User' : 'Activate User',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                            onPressed: () => _deleteUser(user),
                                            tooltip: 'Delete User',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newStatus = user['status'] == 'Active' ? 'Inactive' : 'Active';
      await _firestore.collection('users').doc(user['uid']).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${newStatus == 'Active' ? 'activated' : 'blocked'} successfully',
            style: TextStyle(color: newStatus == 'Active' ? Theme.of(context).colorScheme.onTertiary : Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: newStatus == 'Active' ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user status', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      await _firestore.collection('users').doc(user['uid']).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully', style: TextStyle(color: Theme.of(context).colorScheme.onTertiary)),
          backgroundColor: Theme.of(context).colorScheme.tertiary, // Using tertiary for success
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
