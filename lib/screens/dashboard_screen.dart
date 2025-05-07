import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/sidebar.dart';

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
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (!isSmallScreen) Sidebar(),
          if (isSmallScreen)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isSmallScreen)
                        IconButton(
                          icon: const Icon(Icons.menu),
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
                                    iconColor: Colors.blue[600]!,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Total Objects',
                                    value: dashboardMetrics['Objects']?.toString() ?? '0',
                                    icon: Icons.view_in_ar,
                                    iconColor: Colors.purple[600]!,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Total Users',
                                    value: dashboardMetrics['Users']?.toString() ?? '0',
                                    icon: Icons.people,
                                    iconColor: Colors.green[600]!,
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
                                    iconColor: Colors.orange[600]!,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Approved Forums',
                                    value: dashboardMetrics['Approved Forums']?.toString() ?? '0',
                                    icon: Icons.check_circle,
                                    iconColor: Colors.green[600]!,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth > 900 ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                                  child: _buildStatisticsCard(
                                    title: 'Rejected Forums',
                                    value: dashboardMetrics['Rejected Forums']?.toString() ?? '0',
                                    icon: Icons.cancel,
                                    iconColor: Colors.red[600]!,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                            Colors.blue[50]!,
                            Colors.blue[100]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.place, color: Colors.blue[600], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recent Places",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue[600]),
                  onPressed: () => _fetchDashboardMetrics(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Container(
                height: 400, // Fixed height for the list container
                child: ListView.separated(
                  itemCount: places.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
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
                              color: Colors.grey[100],
                              child: Icon(Icons.image, color: Colors.grey[400], size: 24),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        place['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          place['category'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                            Colors.green[50]!,
                            Colors.green[100]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people, color: Colors.green[600], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Recent Users",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green[600]),
                  onPressed: () => _fetchDashboardMetrics(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Container(
                height: 400, // Fixed height for the list container
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[50],
                        radius: 20,
                        child: Text(
                          (user['username'] as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        user['username'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user['status'] == 'Active'
                            ? Colors.red[50]
                            : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['status'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: user['status'] == 'Active'
                              ? Colors.red[700]
                              : Colors.green[700],
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
                    iconColor.withOpacity(0.09),
                    iconColor.withOpacity(0.09),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
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
                          iconColor.withOpacity(0.15),
                          iconColor.withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                            letterSpacing: 0.5,
                          ),
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
