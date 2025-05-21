import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/sidebar.dart';

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

    await FirebaseFirestore.instance.collection('forums').doc(forumId).update({
      'status': newStatus,
    });
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            flex: 2, // Main content area for forum posts
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container( // Main Header
                  padding: const EdgeInsets.all(32.0), // Consistent padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.04),
                        blurRadius: 16,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Forum Management",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
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
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).shadowColor.withOpacity(0.04),
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedPostId = isSelected ? null : post.id;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16), // Match container's border radius
                                  child: Padding(
                                    padding: EdgeInsets.all(24), // Consistent padding
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container( // Author initial avatar
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                post['authorName'][0].toUpperCase(),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                      fontWeight: FontWeight.bold,
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
                                        ),
                                        if (currentTab == 'Pending')
                                          Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: Row(
                                              children: [
                                                ElevatedButton.icon( // Approve Button
                                                  onPressed: () => _updatePostStatus(post.id, "Approved"),
                                                  icon: Icon(Icons.check_rounded, size: 20),
                                                  label: Text("Approve"),
                                                  style: ElevatedButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                                                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    elevation: 0,
                                                    textStyle: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                OutlinedButton.icon( // Reject Button
                                                  onPressed: () => _updatePostStatus(post.id, "Rejected"),
                                                  icon: Icon(Icons.close_rounded, size: 20),
                                                  label: Text("Reject"),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.error,
                                                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    textStyle: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (post['content'] != null && post['content'].toString().isNotEmpty)
                                          Container( // Post content container
                                            margin: EdgeInsets.only(top: 16),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Theme.of(context).dividerColor),
                                            ),
                                            child: Text( // Content text
                                              post['content'],
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    height: 1.6,
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
          if (selectedPostId != null) // Comments Panel
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
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container( // Author initial avatar
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          comment['authorName']?[0]?.toUpperCase() ?? '?',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text( // Author name
                                              comment['authorName'] ?? 'Anonymous',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                            ),
                                            Text( // Timestamp
                                              _formatTimestamp(comment['createdAt']),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comment['content']?.isNotEmpty ?? false)
                                    Container( // Comment content container
                                      margin: EdgeInsets.only(top: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Theme.of(context).dividerColor),
                                      ),
                                      child: Text( // Comment text
                                        comment['content'],
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              height: 1.5,
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
    return InkWell(
      onTap: () => setState(() => currentTab = title),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Consistent padding
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide( // Selected tab indicator
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text( // Tab text color
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            SizedBox(width: 8),
            StreamBuilder<int>(
              stream: _getStatusCount(title),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) return SizedBox(); // Hide badge if count is 0 or no data
                return Container( // Count badge background
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text( // Count badge text color
                    '${snapshot.data}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
