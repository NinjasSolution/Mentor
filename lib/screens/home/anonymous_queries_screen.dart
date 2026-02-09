import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/services/query_service.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:provider/provider.dart';

class AnonymousQueriesScreen extends StatefulWidget {
  const AnonymousQueriesScreen({super.key});

  @override
  State<AnonymousQueriesScreen> createState() => _AnonymousQueriesScreenState();
}

class _AnonymousQueriesScreenState extends State<AnonymousQueriesScreen> {
  final QueryService _queryService = QueryService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  void _showAddQueryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask Anonymously'),
        content: TextField(
          controller: _questionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What is on your mind?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_questionController.text.trim().isNotEmpty) {
                await _queryService.sendQuery(_questionController.text.trim());
                _questionController.clear();
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question submitted!')));
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(String queryId, String question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Answer Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q: $question', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your answer...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_answerController.text.trim().isNotEmpty) {
                await _queryService.answerQuery(queryId, _answerController.text.trim());
                _answerController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit Answer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We need user role to decide UI
    return FutureBuilder(
      future: Provider.of<AuthService>(context, listen: false).getCurrentUserData(),
      builder: (context, userSnapshot) {
        final String role = userSnapshot.data?.role ?? 'student';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Anonymous Q&A'),
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Answered'),
                    Tab(text: 'Pending'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAnsweredList(),
                      _buildPendingList(role),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: role == 'student' 
            ? FloatingActionButton.extended(
                onPressed: _showAddQueryDialog,
                label: const Text('Ask Question'),
                icon: const Icon(Icons.add_comment),
              )
            : null,
        );
      }
    );
  }

  Widget _buildAnsweredList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _queryService.getAnsweredQueries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No answered queries yet.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q: ${data['question']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    Text('A: ${data['answer']}', style: const TextStyle(color: Colors.blueGrey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _queryService.getPendingQueries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending questions.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(data['question'], style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Waiting for answer...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                trailing: role == 'mentor' 
                  ? ElevatedButton(
                      onPressed: () => _showAnswerDialog(docs[index].id, data['question']),
                      child: const Text('Answer'),
                    )
                  : null,
              ),
            );
          },
        );
      },
    );
  }
}
