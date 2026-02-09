import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String mentorId;
  final String studentId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime assignedAt; // Added to track when task was assigned
  final String status; // 'pending', 'submitted', 'completed', 'graded'
  final String? submissionLink;
  final DateTime? submittedAt;
  final String? attachmentUrl; // Mentor's file attachment
  final String? grade; // Grade/Marks assigned by mentor
  final String? feedback; // Feedback from mentor

  TaskModel({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedAt,
    required this.status,
    this.submissionLink,
    this.submittedAt,
    this.attachmentUrl,
    this.grade,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'studentId': studentId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedAt': Timestamp.fromDate(assignedAt),
      'status': status,
      'submissionLink': submissionLink,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'attachmentUrl': attachmentUrl,
      'grade': grade,
      'feedback': feedback,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      mentorId: map['mentorId'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate() ?? (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      submissionLink: map['submissionLink'],
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      attachmentUrl: map['attachmentUrl'],
      grade: map['grade'],
      feedback: map['feedback'],
    );
  }
}
