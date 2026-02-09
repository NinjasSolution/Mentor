import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String mentorId;
  final String title;
  final String description;
  final String videoUrl;
  final DateTime timestamp;
  final List<String> watchedBy; // List of student IDs who watched this

  CourseModel({
    required this.id,
    required this.mentorId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.timestamp,
    required this.watchedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'watchedBy': watchedBy,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CourseModel(
      id: docId,
      mentorId: map['mentorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      watchedBy: List<String>.from(map['watchedBy'] ?? []),
    );
  }
}
