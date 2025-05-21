import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/sidebar.dart';
import '../utils/app_theme.dart'; // Import app_theme for direct color access if needed

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, int> dashboardMetrics = {
    'Users': 0,
    'Places': 0,
    'Objects': 0,
    'Pending Forums': 0,
    'Approved Forums': 0,
    'Rejected Forums': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  Future<void> _fetchDashboardMetrics() async {
    try {
      var usersSnapshot = await _firestore
          .collection('users')
          .where("role", isNotEqualTo: "Admin")
          .get();

      var placesSnapshot = await _firestore.collection('places').get();

      // var objectsSnapshot = await _firestore.collection('objects').get();

      var pendingForumsSnapshot = await _firestore
          .collection('forums')
          .where('status', isEqualTo: 'Pending')
          .get();

      var approvedForumsSnapshot = await _firestore
          .collection('forums')
          .where('status', isEqualTo: 'Approved')
          .get();

      var rejectedForumsSnapshot = await _firestore
          .collection('forums')
          .where('status', isEqualTo: 'Rejected')
          .get();

      setState(() {
        dashboardMetrics = {
          'Users': usersSnapshot.docs.length,
          'Places': placesSnapshot.docs.length,
          // 'Objects': objectsSnapshot.docs.length,
          'Pending Forums': pendingForumsSnapshot.docs.length,
          'Approved Forums': approvedForumsSnapshot.docs.length,
          'Rejected Forums': rejectedForumsSnapshot.docs.length,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching dashboard metrics: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (!isSmallScreen) Sidebar(),
          // The IconButton for menu on small screens is inside the AppBar or body, 
          // its color will be handled by IconTheme or explicitly if needed.
          // No direct change here, assuming IconTheme from AppBarTheme works.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headline5?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isSmallScreen)
                        IconButton(
                          icon: Icon(Icons.menu, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).iconTheme.color),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Total Places',
                                    value: dashboardMetrics['Places']?.toString() ?? '0',
                                    icon: Icons.place,
                                    iconColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Total Objects',
                                    value: dashboardMetrics['Objects']?.toString() ?? '0',
                                    icon: Icons.view_in_ar,
                                    // Assuming purple is a secondary or tertiary color.
                                    // For now, let's use secondary, or a custom theme color if available.
                                    iconColor: Theme.of(context).colorScheme.secondary, 
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Total Users',
                                    value: dashboardMetrics['Users']?.toString() ?? '0',
                                    icon: Icons.people,
                                    // Using a themed green, e.g. accentColor or a specific theme color
                                    iconColor: accentColor, // from app_theme.dart (or Theme.of(context).colorScheme.tertiary if defined)
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Pending Forums',
                                    value: dashboardMetrics['Pending Forums']?.toString() ?? '0',
                                    icon: Icons.pending_actions,
                                    iconColor: Colors.orange[600]!, // Keep as is or map to a theme color if available
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Approved Forums',
                                    value: dashboardMetrics['Approved Forums']?.toString() ?? '0',
                                    icon: Icons.check_circle,
                                    iconColor: accentColor, // from app_theme.dart
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Rejected Forums',
                                    value: dashboardMetrics['Rejected Forums']?.toString() ?? '0',
                                    icon: Icons.cancel,
                                    iconColor: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                                  child: _buildPlacesList(),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                                  child: _buildUsersList(),
                                ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isSmallScreen ? Sidebar() : null,
    );
  }

  Widget _buildPlacesList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.place, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recent Places",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => _fetchDashboardMetrics(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('places')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final places = snapshot.data!.docs;

              if (places.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No places added yet',
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return Container(
                height: 400, // Fixed height for the list container
                child: ListView.separated(
                  itemCount: places.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final place = places[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          place['imageUrl'] ?? '',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              child: Icon(Icons.image, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        place['title'] ?? '',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          place['category'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people, color: Theme.of(context).colorScheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recent Users",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.secondary),
                  onPressed: () => _fetchDashboardMetrics(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where('role', isNotEqualTo: 'Admin')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No users found',
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return Container(
                height: 400, // Fixed height for the list container
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final bool isActive = user['status'] == 'Active';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                        radius: 20,
                        child: Text(
                          (user['username'] as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        user['username'] ?? '',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                            ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.7)
                            : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7), // Or a specific "success" container
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['status'] ?? 'Unknown',
                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer, // Or a specific "onSuccess" container
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 1, end: 1),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                 boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(0.2),
                          iconColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.1), // Keep this shadow subtle
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 28), // iconColor is dynamic
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
