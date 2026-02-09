import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfilePic;
  final String authorRole;
  final String content;
  final String? imageUrl;
  final String type; // announcement, discussion, resource, event
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfilePic,
    required this.authorRole,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorProfilePic: map['authorProfilePic'],
      authorRole: map['authorRole'] ?? 'student',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      type: map['type'] ?? 'discussion',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfilePic': authorProfilePic,
      'authorRole': authorRole,
      'content': content,
      'imageUrl': imageUrl,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}
