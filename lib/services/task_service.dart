import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'notification_service.dart';
import 'api_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();

  // Mentor assigns a task
  Future<void> assignTask({
    required String mentorId,
    required String studentId,
    required String title,
    required String description,
    required DateTime dueDate,
    String? attachmentUrl,
  }) async {
    final docRef = await _firestore.collection('tasks').add({
      'mentorId': mentorId,
      'studentId': studentId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'attachmentUrl': attachmentUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Sync to MySQL
    final newTask = TaskModel(
      id: docRef.id,
      mentorId: mentorId,
      studentId: studentId,
      title: title,
      description: description,
      dueDate: dueDate,
      assignedAt: DateTime.now(),
      status: 'pending',
      attachmentUrl: attachmentUrl,
    );
    _apiService.syncTaskToMySQL(newTask);

    // Notify Student
    await _notificationService.sendNotification(
      receiverId: studentId,
      title: 'New Task Assigned',
      body: 'Your mentor assigned you a new task: $title',
      type: 'task',
    );
  }

  // Delete a specific task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
    // In a real production app, we would also call a delete API for MySQL
  }

  // Clear all tasks between a mentor and student
  Future<void> clearTasks(String mentorId, String studentId) async {
    final snapshots = await _firestore
        .collection('tasks')
        .where('mentorId', isEqualTo: mentorId)
        .where('studentId', isEqualTo: studentId)
        .get();
    
    WriteBatch batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get tasks for a specific student
  Stream<List<TaskModel>> getStudentTasks(String studentId) {
    return _firestore
        .collection('tasks')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Get tasks assigned by a mentor to a student
  Stream<List<TaskModel>> getMentorStudentTasks(String mentorId, String studentId) {
    return _firestore
        .collection('tasks')
        .where('mentorId', isEqualTo: mentorId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Student submits a task
  Future<void> submitTask(String taskId, String submissionLink) async {
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final mentorId = taskDoc.data()?['mentorId'];
    final title = taskDoc.data()?['title'];

    await _firestore.collection('tasks').doc(taskId).update({
      'submissionLink': submissionLink,
      'status': 'submitted',
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Update Sync to MySQL
    if (taskDoc.exists) {
      final updatedTask = TaskModel.fromMap({
        ...taskDoc.data()!,
        'submissionLink': submissionLink,
        'status': 'submitted',
      }, taskId);
      _apiService.syncTaskToMySQL(updatedTask);
    }

    if (mentorId != null) {
      await _notificationService.sendNotification(
        receiverId: mentorId,
        title: 'Task Submitted',
        body: 'A student has submitted the task: $title',
        type: 'task_submission',
      );
    }
  }

  // Mentor grades a task
  Future<void> gradeTask(String taskId, String grade, String feedback) async {
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final studentId = taskDoc.data()?['studentId'];
    final title = taskDoc.data()?['title'];

    await _firestore.collection('tasks').doc(taskId).update({
      'grade': grade,
      'feedback': feedback,
      'status': 'graded',
    });

    // Update Sync to MySQL
    if (taskDoc.exists) {
      final updatedTask = TaskModel.fromMap({
        ...taskDoc.data()!,
        'grade': grade,
        'feedback': feedback,
        'status': 'graded',
      }, taskId);
      _apiService.syncTaskToMySQL(updatedTask);
    }

    if (studentId != null) {
      await _notificationService.sendNotification(
        receiverId: studentId,
        title: 'Task Graded',
        body: 'Your mentor graded your task "$title": $grade',
        type: 'task',
      );
    }
  }
}
