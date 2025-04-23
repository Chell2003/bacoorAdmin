import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/app_exception.dart';
import '../models/user_model.dart';

/// Manages user authentication state and user data throughout the application.
/// This provider handles all user-related operations including authentication,
/// user data management, and state updates.
class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  User? _user;
  UserModel? _userData;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _userData?.role == 'Admin';
  bool get isAuthenticated => _user != null && _userData != null;

  /// Initializes the user provider by setting up auth state listener
  Future<void> initialize() async {
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }

  /// Handles authentication state changes
  Future<void> _handleAuthStateChange(User? user) async {
    print('Auth state changed: ${user?.email}'); // Debug print
    _user = user;
    _userData = null;
    _error = null;
    notifyListeners();

    if (user != null) {
      try {
        _isLoading = true;
        notifyListeners();

        // Get user data from Firestore
        final userData = await _firestoreService.getUserData(user.uid);
        print('Firestore user data: ${userData?.toMap()}'); // Debug print
        
        if (userData == null) {
          print('Creating new user document'); // Debug print
          // Create new user document if it doesn't exist
          final newUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
            role: 'Admin', // Match the exact case from your Firestore
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          await _firestoreService.createUserDocument(user.uid, newUser);
          _userData = newUser;
        } else {
          print('User role: ${userData.role}'); // Debug print
          _userData = userData;
          // Update last login
          await _firestoreService.updateUserData(
            user.uid,
            {'lastLogin': DateTime.now()},
          );
        }
        _error = null;
      } catch (e) {
        print('Error in auth state change: $e'); // Debug print
        _error = e.toString();
        await signOut();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Signs in the user with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Resets the password for the given email
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 