import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload a new course/video
  Future<void> uploadCourse(String mentorId, String title, String description, String videoUrl) async {
    await _firestore.collection('courses').add({
      'mentorId': mentorId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'watchedBy': [],
    });
  }

  // Get courses for a specific mentor
  Stream<List<CourseModel>> getMentorCourses(String mentorId) {
    return _firestore
        .collection('courses')
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CourseModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get courses only from mentors connected to this student
  Stream<List<CourseModel>> getStudentConnectedCourses(String studentId) {
    return _firestore
        .collection('mentorship_requests')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      
      List<String> mentorIds = snapshot.docs.map((doc) => doc.data()['mentorId'] as String).toList();
      
      if (mentorIds.isEmpty) return [];

      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('mentorId', whereIn: mentorIds)
          .get();

      return coursesSnapshot.docs.map((doc) => CourseModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Save detailed video progress
  Future<void> updateVideoProgress(String userId, String courseId, double progress) async {
    final docId = '${userId}_$courseId';
    await _firestore.collection('video_progress').doc(docId).set({
      'userId': userId,
      'courseId': courseId,
      'progress': progress, // 0.0 to 1.0
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (progress >= 0.9) {
      await markAsWatched(courseId, userId);
    }
  }

  // Get progress for a specific video and user
  Stream<double> getVideoProgress(String userId, String courseId) {
    final docId = '${userId}_$courseId';
    return _firestore
        .collection('video_progress')
        .doc(docId)
        .snapshots()
        .map((doc) => (doc.data()?['progress'] ?? 0.0).toDouble());
  }

  // Mark course as watched by a student
  Future<void> markAsWatched(String courseId, String studentId) async {
    await _firestore.collection('courses').doc(courseId).update({
      'watchedBy': FieldValue.arrayUnion([studentId]),
    });
  }

  // Get all progress for a mentor to see their students' work
  Stream<QuerySnapshot> getAllStudentProgress(String mentorId) {
    // This query would ideally be more complex to join students and courses
    // For now, we'll fetch all progress and filter in UI or use a more flattened approach
    return _firestore.collection('video_progress').snapshots();
  }
}
