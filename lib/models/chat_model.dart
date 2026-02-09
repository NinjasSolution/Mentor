import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

class ChatModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;

  ChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.fileUrl,
    this.fileName,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.toString().split('.').last,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }
}
