import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  String? _userId;
  List<ForumNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Getters
  List<ForumNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Initialize provider with user ID
  void init(String userId) {
    _userId = userId;
    _subscribeToNotifications();
  }

  // Subscribe to notifications stream
  void _subscribeToNotifications() {
    if (_userId == null) return;

    // Listen to notifications
    _notificationService.getNotificationsForUser(_userId!).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error fetching notifications: $error');
      },
    );

    // Listen to unread count
    _notificationService.getUnreadNotificationCount(_userId!).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error fetching unread count: $error');
      },
    );
  }

  // Create a new notification
  Future<void> createNotification(ForumNotification notification) async {
    try {
      debugPrint('Creating notification: ${notification.toMap()}');
      if (_userId == null) {
        debugPrint('Warning: NotificationProvider _userId is null! Make sure init() was called.');
      }
      await _notificationService.createNotification(notification);
      debugPrint('Notification created successfully');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      await _notificationService.markAllNotificationsAsRead(_userId!);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    if (_userId == null) return;

    try {
      await _notificationService.deleteAllNotifications(_userId!);
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Handle post approval notification
  Future<void> notifyPostApproval(String userId, String postId, String postTitle) async {
    final notification = ForumNotification.postApproved(userId, postId, postTitle);
    await createNotification(notification);
  }

  // Handle post rejection notification
  Future<void> notifyPostRejection(String userId, String postId, String postTitle, String reason) async {
    final notification = ForumNotification.postRejected(userId, postId, postTitle, reason);
    await createNotification(notification);
  }

  // Handle new comment notification
  Future<void> notifyNewComment(String userId, String postId, String postTitle, String commentId) async {
    final notification = ForumNotification.newComment(userId, postId, postTitle, commentId);
    await createNotification(notification);
  }

  // Handle new reply notification
  Future<void> notifyNewReply(String userId, String postId, String commentId) async {
    final notification = ForumNotification.newReply(userId, postId, commentId);
    await createNotification(notification);
  }

  // Handle new like notification
  Future<void> notifyNewLike(String userId, String postId, String postTitle) async {
    final notification = ForumNotification.newLike(userId, postId, postTitle);
    await createNotification(notification);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
