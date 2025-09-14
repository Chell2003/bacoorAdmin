import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/sidebar.dart';
import '../../providers/forum_provider.dart';
import '../../providers/notification_provider.dart';

class ForumManagementScreen extends StatefulWidget {
  const ForumManagementScreen({super.key});

  @override
  _ForumManagementScreenState createState() => _ForumManagementScreenState();
}

class _ForumManagementScreenState extends State<ForumManagementScreen> {
  bool isAdmin = false;
  String currentTab = 'Pending';
  String? selectedPostId;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarVisible = true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = userDoc.exists && userDoc['role'] == "Admin";
      });
    }
  }

  Future<void> _updatePostStatus(String forumId, String newStatus) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Only admins can update post status!", style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    try {
      final forumProvider = context.read<ForumService>();
      if (newStatus == "Approved") {
        await forumProvider.approvePost(forumId);
      } else if (newStatus == "Rejected") {
        await forumProvider.rejectPost(forumId, "Post rejected by admin"); // Add a reason if needed
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post ${newStatus.toLowerCase()} successfully'),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating post status: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  Stream<int> _getStatusCount(String status) {
    return FirebaseFirestore.instance
        .collection('forums')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<QuerySnapshot> _getCommentsStream(String postId) {
    return FirebaseFirestore.instance
        .collection('forums')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isSmallScreen ? Sidebar(isVisible: true) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSmallScreen) Sidebar(isVisible: _isSidebarVisible),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isSmallScreen)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                          if (!isSmallScreen)
                            IconButton(
                              icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
                              onPressed: _toggleSidebar,
                            ),
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
                              Icons.forum_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!isSmallScreen)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Forum Management",
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Manage and moderate forum posts",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (isSmallScreen)
                            Text(
                              "Forum Management",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 6 : 8
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: isSmallScreen ? 14 : 16,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              isAdmin ? "Admin Mode" : "View Mode",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container( // Tab Bar
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabWithCount('Pending'),
                      _buildTabWithCount('Approved'),
                      _buildTabWithCount('Rejected'),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('forums')
                        .where('status', isEqualTo: currentTab)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator()); // Default indicator will use theme primary
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error loading forums", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No ${currentTab.toLowerCase()} forums found", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)));
                      }

                      final forums = snapshot.data!.docs;
                      return Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            controller: _scrollController,
                            key: PageStorageKey<String>(currentTab),
                            padding: EdgeInsets.all(24),
                            itemCount: forums.length,
                            itemBuilder: (context, index) {
                              final post = forums[index];
                              final isSelected = selectedPostId == post.id;

                              return Container( // Post container
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedPostId = isSelected ? null : post.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container( // authorAvatar
                                              padding: EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                    spreadRadius: -2,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                post['authorName'][0].toUpperCase(),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text( // Post title
                                                    post['title'],
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                          height: 1.3,
                                                        ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Text( // Author/timestamp text
                                                    "By ${post['authorName']} • ${_formatTimestamp(post['createdAt'])}",
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),                                if (currentTab == 'Pending')
                                          Container(
                                            margin: const EdgeInsets.only(top: 24),
                                            child: Row(
                                              children: [
                                                FilledButton.icon(
                                                  onPressed: () => _updatePostStatus(post.id, "Approved"),
                                                  icon: Icon(Icons.check_circle_rounded, size: 20),
                                                  label: Text("Approve Post"),
                                                  style: FilledButton.styleFrom(
                                                    foregroundColor: Colors.white,
                                                    backgroundColor: Color(0xFF2E7D32),
                                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    elevation: 0,
                                                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                FilledButton.icon(
                                                  onPressed: () => _updatePostStatus(post.id, "Rejected"),
                                                  icon: Icon(Icons.cancel_rounded, size: 20),
                                                  label: Text("Reject Post"),
                                                  style: FilledButton.styleFrom(
                                                    foregroundColor: Colors.white,
                                                    backgroundColor: Theme.of(context).colorScheme.error,
                                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    elevation: 0,
                                                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (post['content'] != null && post['content'].toString().isNotEmpty)
                                          Container(
                                            margin: EdgeInsets.only(top: 20),
                                            padding: EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context).shadowColor.withOpacity(0.03),
                                                  blurRadius: 10,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              post['content'],
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                                height: 1.6,
                                                letterSpacing: 0.15,
                                              ),
                                            ),
                                          ),
                                        if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
                                          Container( // Image section
                                            margin: EdgeInsets.only(top: 16),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Theme.of(context).dividerColor),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                post['imageUrl'],
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) { // Error placeholder
                                                  return Container(
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image_rounded,
                                                          size: 40,
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Text(
                                                          'Image not available',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (selectedPostId != null && !isSmallScreen) // Comments Panel - Only show on large screens
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    blurRadius: 24,
                    offset: Offset(-12, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container( // "Comments" header
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text( // Title text
                          "Comments",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                        ),
                        IconButton( // Close button
                          onPressed: () => setState(() => selectedPostId = null),
                          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          tooltip: 'Close comments',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _getCommentsStream(selectedPostId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator( // Loading indicator
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                            ),
                          );
                        }

                        if (snapshot.hasError) { // Error state
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Error loading comments",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { // Empty state
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No comments yet",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }

                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          padding: EdgeInsets.all(24),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Container( // Comment Item Container
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: Offset(0, 2),
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container( // authorAvatar
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                                              Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          comment['authorName']?[0]?.toUpperCase() ?? '?',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSecondary,
                                            fontWeight: FontWeight.w600,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['authorName'] ?? 'Anonymous',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              _formatTimestamp(comment['createdAt']),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comment['content']?.isNotEmpty ?? false)
                                    Container(
                                      margin: EdgeInsets.only(top: 16),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        comment['content'],
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1.5,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                  if (comment['imageUrl'] != null && comment['imageUrl'].toString().isNotEmpty)
                                    Container( // Image placeholder styling
                                      margin: EdgeInsets.only(top: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Theme.of(context).dividerColor),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          comment['imageUrl'],
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) { // Error placeholder styling
                                            return Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 32,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Image not available',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
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
  Widget _buildTabWithCount(String title) {
    final isSelected = currentTab == title;
    final isSmallScreen = MediaQuery.of(context).size.width < 768;
    Color tabColor;
    IconData tabIcon;
    
    switch(title) {
      case 'Pending':
        tabColor = Color(0xFFFFA000);
        tabIcon = Icons.pending_rounded;
        break;
      case 'Approved':
        tabColor = Color(0xFF2E7D32);
        tabIcon = Icons.check_circle_rounded;
        break;
      case 'Rejected':
        tabColor = Theme.of(context).colorScheme.error;
        tabIcon = Icons.cancel_rounded;
        break;
      default:
        tabColor = Theme.of(context).colorScheme.primary;
        tabIcon = Icons.article_rounded;
    }

    return InkWell(
      onTap: () => setState(() => currentTab = title),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 12 : 16
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? tabColor : Colors.transparent,
              width: 3,
            ),
          ),
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tabColor.withOpacity(0.15),
              tabColor.withOpacity(0.08),
              tabColor.withOpacity(0.02),
            ],
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              tabIcon,
              size: isSmallScreen ? 18 : 22,
              color: isSelected ? tabColor : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? tabColor : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.2,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            StreamBuilder<int>(
              stream: _getStatusCount(title),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) return SizedBox();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tabColor.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? tabColor.withOpacity(0.3)
                          : Theme.of(context).dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${snapshot.data}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected ? tabColor : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    DateTime date = timestamp.toDate();
    Duration difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${date.day}/${date.month}/${date.year}";
  }
}
