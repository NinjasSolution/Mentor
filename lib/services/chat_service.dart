import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  Future<void> sendMessage(String senderId, String receiverId, String text, {MessageType type = MessageType.text, String? fileUrl, String? fileName}) async {
    String chatId = getChatId(senderId, receiverId);
    
    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.toString().split('.').last,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };

    await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);

    String lastMsgText = text;
    if (type == MessageType.image) lastMsgText = "📷 Photo";
    if (type == MessageType.file) lastMsgText = "📁 File: ${fileName ?? 'Document'}";

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': lastMsgText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));

    // Get sender name for notification
    final senderDoc = await _firestore.collection('users').doc(senderId).get();
    final senderName = senderDoc.data()?['name'] ?? 'Someone';

    // Send Real-time Notification WITH senderId for WhatsApp-style badges
    await _notificationService.sendNotification(
      receiverId: receiverId,
      senderId: senderId,
      title: 'New Message from $senderName',
      body: lastMsgText,
      type: 'chat',
    );
  }

  Future<void> deleteMessage(String senderId, String receiverId, String messageId) async {
    String chatId = getChatId(senderId, receiverId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Clear all messages in a chat
  Future<void> clearChat(String user1, String user2) async {
    String chatId = getChatId(user1, user2);
    final messages = await _firestore.collection('chats').doc(chatId).collection('messages').get();
    
    WriteBatch batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    // Update last message
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': 'Messages cleared',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // Delete the entire chat entry
  Future<void> deleteChat(String user1, String user2) async {
    String chatId = getChatId(user1, user2);
    
    // First clear messages
    await clearChat(user1, user2);
    
    // Then delete the chat document itself
    await _firestore.collection('chats').doc(chatId).delete();
  }

  Stream<List<ChatModel>> getMessages(String user1, String user2) {
    String chatId = getChatId(user1, user2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<QuerySnapshot> getActiveChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }
}
