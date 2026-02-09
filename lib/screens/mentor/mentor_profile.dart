import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MentorProfile extends StatelessWidget {
  const MentorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('mentors').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skills: ${data['skills'].join(', ')}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('Experience: ${data['experience']} years'),
                const SizedBox(height: 10),
                Text('Bio: ${data['bio']}'),
              ],
            ),
          );
        },
      ),
    );
  }
}