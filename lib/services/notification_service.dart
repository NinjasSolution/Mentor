import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String baseUrl = "https://mudassar.ahmeii.online/api";

  Future<void> initFCM() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "",
      platformDetails,
    );
  }

  Future<void> saveToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Token Save Error: $e");
    }
  }

  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    String? senderId, // Tracking who sent it
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'senderId': senderId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final String? fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        await http.post(
          Uri.parse('$baseUrl/send_push.php'),
          body: {
            'token': fcmToken,
            'title': title,
            'body': body,
          },
        );
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications from a specific sender as read
  Future<void> markSenderNotificationsRead(String userId, String senderId) async {
    final snapshots = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('senderId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (var doc in snapshots.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");
}
