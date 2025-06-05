import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/sidebar.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late List<Animation<double>> _animations;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _isSidebarVisible = true;

  Map<String, int> dashboardMetrics = {
    'Users': 0,
    'Places': 0,
    'Objects': 0,
    'Pending Forums': 0,
    'Approved Forums': 0,
    'Rejected Forums': 0,
  };
  List<Map<String, dynamic>> recentForums = [];
  List<Map<String, dynamic>> activeUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
    _fetchRecentForums();
    _fetchActiveUsers();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            (index * 0.1) + 0.5,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardMetrics() async {
    try {
      var usersSnapshot = await _firestore
          .collection('users')
          .where("role", isNotEqualTo: "Admin")
          .get();

      var placesSnapshot = await _firestore.collection('places').get();

      var objectsSnapshot = await _firestore.collection('ar_objects').get();

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
          'Objects': objectsSnapshot.docs.length,
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

  Future<void> _fetchRecentForums() async {
    try {
      var forumsSnapshot = await _firestore
          .collection('forums')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        recentForums = forumsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'title': doc['title'] ?? '',
                  'status': doc['status'] ?? 'Pending',
                  'author': doc['authorName'] ?? 'Unknown',
                  'createdAt': doc['createdAt'] as Timestamp,
                })
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching recent forums: $e");
      }
    }
  }  Future<void> _fetchActiveUsers() async {
    try {      var usersSnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'Admin')
          .limit(5)
          .get();

      setState(() {
        activeUsers = usersSnapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'username': data['username'] ?? 'Unknown User',
                'email': data['email'] ?? '',
                'photoURL': data['photoURL'] ?? '',
                'status': data['status'] ?? 'inactive',
                'role': data['role'] ?? 'user',
                'bio': data['bio'] ?? '',
                'createdAt': data['createdAt'] as Timestamp,
              };
            })
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching active users: $e");
      }
    }
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color, Animation<double> animation) {    return ScaleTransition(
      scale: animation,      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.15),
              color.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Handle card tap
              },
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(spacingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(spacingSmall),
                              decoration: BoxDecoration(                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withOpacity(0.2),
                                    color.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(borderRadiusMedium),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ],
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: spacingSmall,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withOpacity(0.1),
                                    color.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(borderRadiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: color,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${value > 10 ? value ~/ 10 : value}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: spacingLarge),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0, end: value.toDouble()),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: spacingSmall),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentForumsTable() {
    return Container(
      margin: const EdgeInsets.only(top: spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(spacingSmall),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: spacingMedium),
                        Text(
                          'Recent Forum Posts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: spacingSmall),
                    Text(
                      'Latest forum activities and discussions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forum');
                  },
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacingMedium,
                      vertical: spacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusMedium),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
                dataTableTheme: DataTableTheme.of(context).copyWith(
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: spacingLarge,
                headingRowHeight: 56,
                dataRowHeight: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadiusLarge),
                ),
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  },
                ),
                columns: [
                  DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: spacingSmall),
                          Text('Title'),
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: spacingSmall),
                          Text('Author'),
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: spacingSmall),
                          Text('Status'),
                        ],
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: spacingMedium, vertical: spacingSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: spacingSmall),
                          Text('Date'),
                        ],
                      ),
                    ),
                  ),
              ],
              rows: recentForums.map((forum) {
                Color statusColor;
                IconData statusIcon;
                switch (forum['status']) {
                  case 'Approved':
                    statusColor = successColor;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'Rejected':
                    statusColor = errorColor;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = warningColor;
                    statusIcon = Icons.pending;
                }

                return DataRow(
                  cells: [                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingMedium,
                          vertical: spacingSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: Icon(
                                Icons.article_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: spacingMedium),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    forum['title'],
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Forum post',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingMedium,
                          vertical: spacingSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                child: Text(
                                  forum['author'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: spacingMedium),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  forum['author'],
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Author',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingMedium,
                          vertical: spacingSmall,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: spacingMedium,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    statusColor.withOpacity(0.15),
                                    statusColor.withOpacity(0.25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(borderRadiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    forum['status'],
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current status',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingMedium,
                          vertical: spacingSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadiusSmall),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: spacingMedium),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM d, y').format(
                                    (forum['createdAt'] as Timestamp).toDate(),
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Creation date',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          
          ),
        ],
    ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      margin: const EdgeInsets.only(top: spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(spacingSmall),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.people_alt_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: spacingMedium),
                        Text(
                          'Active Users',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: spacingSmall),
                    Text(
                      'List of registered users',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/users');
                  },
                  icon: const Icon(Icons.people_alt_outlined),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacingMedium,
                      vertical: spacingSmall,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadiusMedium),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Users List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: spacingLarge),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeUsers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final user = activeUsers[index];
                final username = user['username'] ?? 'Unknown User';
                final String initials = username.split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();
                final bool isActive = user['status'] == 'active';
                final String photoURL = user['photoURL'] ?? '';
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: spacingMedium,
                    vertical: spacingSmall,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                    child: photoURL.isEmpty ? Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ) : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: spacingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.green.withOpacity(0.1)
                              : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(borderRadiusSmall),
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
                                color: isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            Text(
                              user['status'] ?? 'inactive',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        user['role'] ?? 'user',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Show user actions menu
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: spacingLarge),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isSmallScreen ? const Sidebar(isVisible: true) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSmallScreen) const Sidebar(isVisible: true),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: surfaceColor,
                  toolbarHeight: 80,
                  leading: isSmallScreen
                      ? IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        )
                      : null,
                  title: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back, Admin',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: secondaryColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: spacingMedium),
                      padding: const EdgeInsets.symmetric(
                        horizontal: spacingSmall,
                        vertical: spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(borderRadiusMedium),
                        border: Border.all(
                          color: dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: spacingSmall),
                          Text(
                            DateFormat('MMMM d, y').format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: spacingLarge),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(spacingXSmall),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.refresh_outlined,
                            color: primaryColor,
                          ),
                        ),                        onPressed: () {
                          _fetchDashboardMetrics();
                          _fetchRecentForums();
                          _fetchActiveUsers();
                        },
                        tooltip: 'Refresh All Data',
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(spacingLarge),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metrics Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double cardWidth = constraints.maxWidth > 1200 ? constraints.maxWidth / 3 - spacingLarge : constraints.maxWidth / 2 - spacingMedium;
                            return Wrap(
                              spacing: spacingLarge,
                              runSpacing: spacingLarge,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Users',
                                    dashboardMetrics['Users'] ?? 0,
                                    Icons.people_alt_outlined,
                                    Theme.of(context).colorScheme.primary,
                                    _animations[0],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Places',
                                    dashboardMetrics['Places'] ?? 0,
                                    Icons.place_outlined,
                                    Theme.of(context).colorScheme.secondary,
                                    _animations[1],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Objects',
                                    dashboardMetrics['Objects'] ?? 0,
                                    Icons.view_in_ar_outlined,
                                    Theme.of(context).colorScheme.tertiary,
                                    _animations[2],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Pending Forums',
                                    dashboardMetrics['Pending Forums'] ?? 0,
                                    Icons.pending_outlined,
                                    Colors.orange,
                                    _animations[3],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Approved Forums',
                                    dashboardMetrics['Approved Forums'] ?? 0,
                                    Icons.check_circle_outline,
                                    Colors.green,
                                    _animations[4],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    'Rejected Forums',
                                    dashboardMetrics['Rejected Forums'] ?? 0,
                                    Icons.cancel_outlined,
                                    Colors.red,
                                    _animations[5],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Responsive layout for tables
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 1100) {
                              // Stack tables vertically on small screens
                              return Column(
                                children: [
                                  _buildRecentForumsTable(),
                                  const SizedBox(height: spacingLarge),
                                  _buildUsersTable(),
                                ],
                              );
                            } else {
                              // Side by side on larger screens
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildRecentForumsTable(),
                                  ),
                                  const SizedBox(width: spacingLarge),
                                  Expanded(
                                    child: _buildUsersTable(),
                                  ),
                                ],
                              );
                            }
                          },
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
    );
  }
}
