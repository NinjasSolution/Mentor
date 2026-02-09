import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/widgets/custom_textfield.dart';

class StudentChat extends StatefulWidget {
  const StudentChat({super.key});

  @override
  State<StudentChat> createState() => _StudentChatState();
}

class _StudentChatState extends State<StudentChat> {
  final TextEditingController messageController = TextEditingController();
  String receiverId = ''; // Enter mentor ID

  @override
  Widget build(BuildContext context) {
    String senderId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Mentor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => receiverId = value),
              decoration: const InputDecoration(
                hintText: 'Enter Mentor ID to Start Chat',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: receiverId.isEmpty
                ? const Center(child: Text('Enter an ID to load messages'))
                : StreamBuilder<List<ChatModel>>(
                    stream: ChatService().getMessages(senderId, receiverId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }
                      
                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          ChatModel chat = snapshot.data![index];
                          bool isMe = chat.senderId == senderId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(chat.text),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(hintText: 'Type message...', controller: messageController),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (messageController.text.isNotEmpty && receiverId.isNotEmpty) {
                      ChatService().sendMessage(senderId, receiverId, messageController.text);
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
