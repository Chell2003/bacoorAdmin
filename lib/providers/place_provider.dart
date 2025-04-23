import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';
import '../utils/app_exception.dart';

class PlaceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PlaceModel> _places = [];
  bool _isLoading = false;
  String? _error;

  List<PlaceModel> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all places from Firestore
  Future<void> fetchPlaces() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('places')
          .orderBy('timestamp', descending: true)
          .get();

      _places = snapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Failed to fetch places: $e';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new place to Firestore
  Future<void> addPlace(PlaceModel place) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('places').add(place.toMap());
      await fetchPlaces(); // Refresh the list
    } catch (e) {
      _error = 'Failed to add place: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a place from Firestore
  Future<void> deletePlace(String placeId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('places').doc(placeId).delete();
      await fetchPlaces(); // Refresh the list
    } catch (e) {
      _error = 'Failed to delete place: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates a place in Firestore
  Future<void> updatePlace(PlaceModel place) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('places').doc(place.id).update(place.toMap());
      await fetchPlaces(); // Refresh the list
    } catch (e) {
      _error = 'Failed to update place: $e';
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