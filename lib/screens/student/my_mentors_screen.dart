import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/services/mentor_service.dart';
import 'package:bgnu_mentor/models/mentor_model.dart';
import 'mentor_profile_screen.dart';

class MyMentorsScreen extends StatelessWidget {
  const MyMentorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mentorService = MentorService();
    final String currentStudentId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentors'),
      ),
      body: StreamBuilder<List<MentorModel>>(
        stream: mentorService.getConnectedMentors(currentStudentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('You haven\'t connected with any mentors yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final mentors = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mentors.length,
            itemBuilder: (context, index) {
              final mentor = mentors[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: mentor.profilePicUrl != null ? NetworkImage(mentor.profilePicUrl!) : null,
                    child: mentor.profilePicUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(mentor.name ?? 'Mentor', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(mentor.skills.take(2).join(', ')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MentorProfileScreen(mentor: mentor),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
