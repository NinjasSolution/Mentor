import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'mentor_list.dart';
import 'student_chat.dart';
import 'package:bgnu_mentor/widgets/custom_button.dart';
import 'package:bgnu_mentor/widgets/custom_textfield.dart';
import '../profile/profile_screen.dart';  // <-- ye add kar do
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome Student!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            CustomButton(
              text: 'View Mentors',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorList())),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Chat with Mentor',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentChat())),
            ),
            ElevatedButton(
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>  ProfileScreen()));
  },
  child: const Text('My Profile'),
),
          ],
        ),
      ),
    );
  }
}