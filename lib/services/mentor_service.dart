import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mentor_model.dart';
import 'notification_service.dart';
import 'api_service.dart';

class MentorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();

  // --- Mentor Application ---

  Future<void> submitMentorDetails(
    String userId,
    List<String> skills,
    String experience,
    String bio,
    String phone,
    String? picUrl,
    {String? linkedin, String? github, String? youtube}
  ) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'skills': skills,
      'experience': experience,
      'bio': bio,
      'phone': phone,
      'profilePicUrl': picUrl,
      'linkedinUrl': linkedin,
      'githubUrl': github,
      'youtubeUrl': youtube,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
      'averageRating': 0.0,
      'ratingCount': 0,
    };

    await _firestore.collection('mentor_requests').doc(userId).set(data);

    // Auto-sync request to MySQL
    _apiService.syncMentorToMySQL(MentorModel.fromMap(data));

    _notificationService.sendNotification(
      receiverId: 'admin_central', 
      title: 'New Mentor Application',
      body: 'A new user has applied to be a mentor.',
      type: 'mentor_request',
    );
  }

  // --- Rating System ---
  Future<void> rateMentor(String mentorId, String studentId, double rating, String review) async {
    final enrollment = await _firestore.collection('mentorship_requests').doc('${studentId}_${mentorId}').get();
    if (!enrollment.exists || enrollment.data()?['status'] != 'accepted') {
      throw Exception("You can only rate mentors you are actively enrolled with.");
    }

    final ratingRef = _firestore.collection('mentors').doc(mentorId).collection('ratings').doc(studentId);
    await ratingRef.set({
      'studentId': studentId,
      'rating': rating,
      'review': review,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final mentorDoc = _firestore.collection('mentors').doc(mentorId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(mentorDoc);
      if (!snapshot.exists) return;

      final ratingsSnapshot = await _firestore.collection('mentors').doc(mentorId).collection('ratings').get();
      double total = 0;
      for (var doc in ratingsSnapshot.docs) {
        total += (doc.data()['rating'] ?? 0.0);
      }
      
      final double newAvg = total / ratingsSnapshot.docs.length;
      final int newCount = ratingsSnapshot.docs.length;

      transaction.update(mentorDoc, {
        'averageRating': newAvg,
        'ratingCount': newCount,
      });

      // Auto-sync updated rating to MySQL
      final mentorData = snapshot.data() as Map<String, dynamic>;
      _apiService.syncMentorToMySQL(MentorModel.fromMap({
        ...mentorData,
        'averageRating': newAvg,
        'ratingCount': newCount,
      }));
    });
  }

  Stream<List<MentorModel>> getPendingRequests() {
    return _firestore
        .collection('mentor_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<MentorModel> mentors = [];
      for (var doc in snapshot.docs) {
        final mentorData = doc.data();
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final combinedData = {
            ...mentorData,
            'name': userData['name'],
            'email': userData['email'],
          };
          mentors.add(MentorModel.fromMap(combinedData));
        }
      }
      return mentors;
    });
  }

  Future<void> approveMentor(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'approved',
      'role': 'mentor'
    });

    await _firestore.collection('mentor_requests').doc(userId).update({'status': 'approved'});
    
    DocumentSnapshot request = await _firestore.collection('mentor_requests').doc(userId).get();
    if (request.exists) {
      Map<String, dynamic> data = request.data() as Map<String, dynamic>;
      data['approvedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('mentors').doc(userId).set(data);
      
      // Auto-sync to MySQL mentors table
      _apiService.syncMentorToMySQL(MentorModel.fromMap(data));
    }

    await _notificationService.sendNotification(
      receiverId: userId,
      title: 'Application Approved! 🎉',
      body: 'Congratulations! You are now a Mentor.',
      type: 'role_update',
    );
  }

  Future<void> rejectMentor(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'rejected',
      'role': 'student' 
    });
    await _firestore.collection('mentors').doc(userId).delete();
    await _firestore.collection('mentor_requests').doc(userId).update({'status': 'rejected'});

    await _notificationService.sendNotification(
      receiverId: userId,
      title: 'Application Update',
      body: 'Your mentor application was not approved at this time.',
      type: 'role_update',
    );
  }

  // Discovery
  Stream<List<MentorModel>> getApprovedMentors() {
    return _firestore.collection('mentors').snapshots().asyncMap((snapshot) async {
      List<MentorModel> mentors = [];
      for (var doc in snapshot.docs) {
        final mentorData = doc.data();
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final combinedData = {
            ...mentorData,
            'name': userData['name'],
            'email': userData['email'],
          };
          mentors.add(MentorModel.fromMap(combinedData));
        }
      }
      return mentors;
    });
  }

  Stream<List<MentorModel>> getConnectedMentors(String studentId) {
    return _firestore
        .collection('mentorship_requests')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      List<MentorModel> mentors = [];
      for (var doc in snapshot.docs) {
        final mentorId = doc.data()['mentorId'];
        final mentorDoc = await _firestore.collection('mentors').doc(mentorId).get();
        if (mentorDoc.exists) {
          final mentorData = mentorDoc.data() as Map<String, dynamic>;
          final userDoc = await _firestore.collection('users').doc(mentorId).get();
          if (userDoc.exists) {
            mentorData['name'] = (userDoc.data() as Map<String, dynamic>)['name'];
            mentorData['email'] = (userDoc.data() as Map<String, dynamic>)['email'];
          }
          mentors.add(MentorModel.fromMap(mentorData));
        }
      }
      return mentors;
    });
  }

  // --- Mentorship Requests ---

  Future<void> sendMentorshipRequest(String studentId, String mentorId, String message) async {
    final Map<String, dynamic> data = {
      'studentId': studentId,
      'mentorId': mentorId,
      'message': message,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docId = '${studentId}_${mentorId}';
    await _firestore.collection('mentorship_requests').doc(docId).set(data);

    // Auto-sync to MySQL
    _apiService.syncMentorshipRequestToMySQL({
      ...data,
      'id': docId,
    });

    final studentDoc = await _firestore.collection('users').doc(studentId).get();
    final studentName = studentDoc.data()?['name'] ?? 'A student';

    await _notificationService.sendNotification(
      receiverId: mentorId,
      title: 'New Mentorship Request',
      body: '$studentName wants to connect with you.',
      type: 'mentorship_request',
    );
  }

  Future<void> updateMentorshipRequestStatus(String requestId, String status) async {
    await _firestore.collection('mentorship_requests').doc(requestId).update({
      'status': status,
    });

    final doc = await _firestore.collection('mentorship_requests').doc(requestId).get();
    if (doc.exists) {
      _apiService.syncMentorshipRequestToMySQL({
        ...doc.data()!,
        'id': requestId,
      });
    }

    final studentId = doc.data()?['studentId'];
    final mentorId = doc.data()?['mentorId'];

    if (studentId != null) {
      final mentorDoc = await _firestore.collection('users').doc(mentorId).get();
      final mentorName = mentorDoc.data()?['name'] ?? 'Mentor';

      await _notificationService.sendNotification(
        receiverId: studentId,
        title: 'Mentorship Request Update',
        body: 'Your request has been $status by $mentorName.',
        type: 'mentorship_update',
      );
    }
  }

  Stream<DocumentSnapshot> getRequestStatus(String studentId, String mentorId) {
    return _firestore.collection('mentorship_requests').doc('${studentId}_${mentorId}').snapshots();
  }

  Stream<List<Map<String, dynamic>>> getMentorshipRequestsForMentor(String mentorId, {String status = 'pending'}) {
    return _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: status)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> requests = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;
        var studentDoc = await _firestore.collection('users').doc(data['studentId']).get();
        if (studentDoc.exists) {
          data['studentName'] = studentDoc.data()?['name'] ?? 'Unknown';
          data['studentPic'] = studentDoc.data()?['profilePicUrl'];
        }
        requests.add(data);
      }
      return requests;
    });
  }
}
