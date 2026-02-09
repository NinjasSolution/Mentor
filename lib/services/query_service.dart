import 'package:cloud_firestore/cloud_firestore.dart';

class QueryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student sends an anonymous query
  Future<void> sendQuery(String question) async {
    await _firestore.collection('queries').add({
      'question': question,
      'answer': '',
      'isAnswered': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mentor gets all unanswered queries
  Stream<QuerySnapshot> getPendingQueries() {
    // Removed orderBy to avoid Index requirement for now
    return _firestore
        .collection('queries')
        .where('isAnswered', isEqualTo: false)
        .snapshots();
  }

  // Mentor answers a query
  Future<void> answerQuery(String queryId, String answer) async {
    await _firestore.collection('queries').doc(queryId).update({
      'answer': answer,
      'isAnswered': true,
    });
  }

  // Everyone can see answered queries
  Stream<QuerySnapshot> getAnsweredQueries() {
    // Removed orderBy to avoid Index requirement for now
    return _firestore
        .collection('queries')
        .where('isAnswered', isEqualTo: true)
        .snapshots();
  }
}
