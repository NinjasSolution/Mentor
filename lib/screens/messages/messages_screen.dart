import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/services/chat_service.dart';
import 'package:bgnu_mentor/models/chat_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/full_screen_image_view.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ChatService _chatService = ChatService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('My Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getActiveChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No conversations yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 80, color: isDark ? Colors.white10 : Colors.grey[200]),
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(chatData['participants'] ?? []);
              final receiverId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
              if (receiverId.isEmpty) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final String userName = userData?['name'] ?? 'User';
                  final String? userPic = userData?['profilePicUrl'];
                  final String userRole = userData?['role'] ?? 'student';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .collection('notifications')
                        .where('senderId', isEqualTo: receiverId)
                        .where('isRead', isEqualTo: false)
                        .where('type', isEqualTo: 'chat')
                        .snapshots(),
                    builder: (context, notifSnapshot) {
                      int unreadCount = notifSnapshot.hasData ? notifSnapshot.data!.docs.length : 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: (userPic != null && userPic.isNotEmpty) ? NetworkImage(userPic) : null,
                          child: (userPic == null || userPic.isEmpty) ? const Icon(Icons.person) : null,
                        ),
                        title: Row(
                          children: [
                            Text(userName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            if (userRole == 'admin') ...[
                              const SizedBox(width: 8),
                              _buildAdminBadge(),
                            ],
                          ],
                        ),
                        subtitle: Text(chatData['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chatData['lastMessageTime'] != null)
                              Text(DateFormat('hh:mm a').format((chatData['lastMessageTime'] as Timestamp).toDate()), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 5),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverId: receiverId, receiverName: userName, receiverRole: userRole))),
                      );
                    }
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withOpacity(0.5))),
      child: const Text('ADMIN', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverRole;
  const ChatPage({super.key, required this.receiverId, required this.receiverName, this.receiverRole = 'student'});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _notificationService.markSenderNotificationsRead(_currentUserId, widget.receiverId);
  }

  void _deleteMessage(String msgId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('Are you sure you want to delete this message for everyone?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.deleteMessage(_currentUserId, widget.receiverId, msgId);
    }
  }

  void _showChatMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'clear',
          child: Row(children: [Icon(Icons.cleaning_services, size: 20), SizedBox(width: 8), Text('Clear Chat')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_forever, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete Chat', style: TextStyle(color: Colors.red))]),
        ),
      ],
    ).then((value) {
      if (value == 'clear') _clearChat();
      if (value == 'delete') _deleteChat();
    });
  }

  void _clearChat() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all messages in this conversation. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.clearChat(_currentUserId, widget.receiverId);
    }
  }

  void _deleteChat() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text('This will delete the entire conversation from your list. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.deleteChat(_currentUserId, widget.receiverId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        _uploadFile(bytes, pickedFile.name, isImage: true);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        _uploadFile(result.files.single.bytes!, result.files.single.name, isImage: false);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _uploadFile(Uint8List fileBytes, String fileName, {required bool isImage}) async {
    setState(() => _isUploading = true);
    try {
      final String? fileUrl = await _apiService.uploadTaskFile(
        _currentUserId + DateTime.now().millisecondsSinceEpoch.toString(), 
        fileBytes, 
        fileName
      );
      
      if (fileUrl != null) {
        await _chatService.sendMessage(
          _currentUserId, 
          widget.receiverId, 
          isImage ? "Sent a photo" : "Sent a file: $fileName",
          type: isImage ? MessageType.image : MessageType.file,
          fileUrl: fileUrl,
          fileName: fileName
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.receiverName),
            if (widget.receiverRole == 'admin') ...[
              const SizedBox(width: 8),
              _buildAdminBadge(),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getMessages(_currentUserId, widget.receiverId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg.senderId == _currentUserId;
                    return GestureDetector(
                      onLongPress: isMe ? () => _deleteMessage(msg.id) : null,
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            _buildMessageContent(msg, isMe, isDark),
                            Text(DateFormat('hh:mm a').format(msg.timestamp), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withOpacity(0.5))),
      child: const Text('ADMIN', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildMessageContent(ChatModel msg, bool isMe, bool isDark) {
    if (msg.type == MessageType.image) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrl: msg.fileUrl!))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[700] : (isDark ? const Color(0xFF161B22) : Colors.grey[200]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              msg.fileUrl!, 
              width: 200, 
              height: 200, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
        ),
      );
    } else if (msg.type == MessageType.file) {
      return InkWell(
        onTap: () => launchUrl(Uri.parse(msg.fileUrl!), mode: LaunchMode.externalApplication),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue[700] : (isDark ? const Color(0xFF161B22) : Colors.grey[200]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.blue),
              const SizedBox(width: 8),
              Flexible(child: Text(msg.fileName ?? "File", style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87)))),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[700] : (isDark ? const Color(0xFF161B22) : Colors.grey[200]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87))),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blue),
            onPressed: _showAttachmentSheet,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                _chatService.sendMessage(_currentUserId, widget.receiverId, _messageController.text.trim());
                _messageController.clear();
              }
            },
            icon: const Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }
}
