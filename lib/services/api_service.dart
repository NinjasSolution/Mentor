import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/post_model.dart';
import '../models/mentor_model.dart';

class ApiService {
  static const String baseUrl = "https://mudassar.ahmeii.online/api";

  // --- Flexible User Sync based on Role ---
  Future<void> syncUserByRole(UserModel user, {MentorModel? mentorDetails}) async {
    String endpoint = "";
    Map<String, dynamic> body = {
      'firebase_uid': user.id,
      'name': user.name,
      'email': user.email,
      'profile_pic_url': user.profilePicUrl,
    };

    if (user.role == 'student') {
      endpoint = "sync_student.php";
      body['status'] = user.status;
    } else if (user.role == 'mentor') {
      endpoint = "sync_mentor.php";
      body['status'] = user.status;
      if (mentorDetails != null) {
        body.addAll({
          'skills': mentorDetails.skills.join(', '),
          'experience': mentorDetails.experience,
          'bio': mentorDetails.bio,
          'phone': mentorDetails.phone,
          'linkedin_url': mentorDetails.linkedinUrl,
          'github_url': mentorDetails.githubUrl,
          'youtube_url': mentorDetails.youtubeUrl,
          'average_rating': mentorDetails.averageRating,
          'rating_count': mentorDetails.ratingCount,
        });
      }
    } else if (user.role == 'admin') {
      endpoint = "sync_admin.php";
    }

    if (endpoint.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
      } catch (e) {
        debugPrint("Error syncing ${user.role}: $e");
      }
    }
  }

  // Backward compatibility
  Future<bool> syncUser(UserModel user) async {
    await syncUserByRole(user);
    return true;
  }

  // --- Mentorship Request Sync ---
  Future<void> syncMentorshipRequestToMySQL(Map<String, dynamic> request) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sync_mentorship_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_request_id': request['id'],
          'student_id': request['studentId'],
          'mentor_id': request['mentorId'],
          'message': request['message'],
          'status': request['status'],
          'timestamp': request['timestamp']?.toString(),
        }),
      );
    } catch (e) {
      debugPrint("MySQL Mentorship Sync Error: $e");
    }
  }

  // --- Task Sync ---
  Future<void> syncTaskToMySQL(TaskModel task) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sync_task.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_task_id': task.id,
          'mentor_id': task.mentorId,
          'student_id': task.studentId,
          'title': task.title,
          'description': task.description,
          'due_date': task.dueDate.toIso8601String(),
          'status': task.status,
          'attachment_url': task.attachmentUrl,
          'submission_link': task.submissionLink,
          'grade': task.grade,
          'feedback': task.feedback,
        }),
      );
    } catch (e) {
      debugPrint("MySQL Task Sync Error: $e");
    }
  }

  // --- Post Sync ---
  Future<void> syncPostToMySQL(PostModel post) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sync_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_post_id': post.id,
          'author_id': post.authorId,
          'content': post.content,
          'image_url': post.imageUrl,
          'post_type': post.type,
        }),
      );
    } catch (e) {
      debugPrint("MySQL Post Sync Error: $e");
    }
  }

  // File Upload Helpers
  Future<String?> uploadTaskFile(String taskId, Uint8List fileBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_task.php'));
      request.fields['task_id'] = taskId;
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['url'];
      }
      return null;
    } catch (e) { return null; }
  }

  Future<String?> uploadProfilePic(String uid, Uint8List fileBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_profile_pic.php'));
      request.fields['firebase_uid'] = uid;
      request.files.add(http.MultipartFile.fromBytes('image', fileBytes, filename: fileName));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['url'];
      }
      return null;
    } catch (e) { return null; }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/delete_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_uid': uid}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // Added missing method
  Future<void> syncMentorToMySQL(MentorModel mentor) async {
    await syncUserByRole(
      UserModel(id: mentor.userId, name: mentor.name ?? '', email: mentor.email ?? '', role: 'mentor', status: 'approved', profilePicUrl: mentor.profilePicUrl),
      mentorDetails: mentor
    );
  }
}
