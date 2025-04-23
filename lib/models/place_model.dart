import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String category;
  final String lat;
  final String long;
  final int likes;
  final List<String> likedBy;
  final DateTime timestamp;

  PlaceModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.lat,
    required this.long,
    required this.likes,
    required this.likedBy,
    required this.timestamp,
  });

  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return PlaceModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      lat: data['lat'] ?? '',
      long: data['long'] ?? '',
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'category': category,
      'lat': lat,
      'long': long,
      'likes': likes,
      'likedBy': likedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  PlaceModel copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    String? category,
    String? lat,
    String? long,
    int? likes,
    List<String>? likedBy,
    DateTime? timestamp,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 