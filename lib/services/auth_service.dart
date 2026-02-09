import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserModel> signup(String name, String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String status = role == 'mentor' ? 'pending' : 'approved';

      UserModel user = UserModel(
        id: cred.user!.uid,
        name: name,
        email: email.trim(),
        role: role,
        status: status,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(user.toMap());
      await _apiService.syncUser(user).catchError((e) => debugPrint("MySQL Sync Error: $e"));

      notifyListeners();
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Signup error: $e');
      throw Exception('An unexpected error occurred during signup.');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        UserModel user = UserModel.fromMap(data, doc.id);
        _apiService.syncUser(user).catchError((e) => debugPrint("MySQL Background Sync Error: $e"));
        notifyListeners();
        return user;
      } else {
        throw Exception('User data not found.');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  // Account Deletion
  Future<void> deleteAccount(String password) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);

      String uid = user.uid;
      await _firestore.collection('users').doc(uid).delete();
      await _firestore.collection('mentors').doc(uid).delete();
      await _firestore.collection('mentor_requests').doc(uid).delete();
      
      await _apiService.deleteUser(uid).catchError((e) => debugPrint("MySQL Delete Error: $e"));
      await user.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') throw Exception("Incorrect password.");
      rethrow;
    }
  }
}
