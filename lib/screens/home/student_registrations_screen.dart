import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bgnu_mentor/services/mentor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentRegistrationsScreen extends StatelessWidget {
  const StudentRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mentorService = MentorService();
    final String currentMentorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship Requests'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: mentorService.getMentorshipRequestsForMentor(currentMentorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending requests yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request, mentorService);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request, MentorService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: request['studentPic'] != null 
                    ? NetworkImage(request['studentPic']) 
                    : null,
                  child: request['studentPic'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['studentName'] ?? 'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text('Requested Mentorship', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(request['message'] ?? 'No message provided.', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRequest(context, request['id'], 'rejected', service),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRequest(context, request['id'], 'accepted', service),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleRequest(BuildContext context, String requestId, String status, MentorService service) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status[0].toUpperCase()}${status.substring(1)} Request?'),
        content: Text('Are you sure you want to $status this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.updateMentorshipRequestStatus(requestId, status);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request $status successfully.')),
              );
            },
            child: Text(status[0].toUpperCase() + status.substring(1)),
          ),
        ],
      ),
    );
  }
}
