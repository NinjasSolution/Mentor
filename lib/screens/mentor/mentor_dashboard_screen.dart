import 'package:bgnu_mentor/screens/home/anonymous_queries_screen.dart';
import 'package:bgnu_mentor/screens/home/courses_screen.dart';
import 'package:bgnu_mentor/screens/home/student_registrations_screen.dart';
import 'package:flutter/material.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:provider/provider.dart';

class MentorDashboardScreen extends StatelessWidget {
  const MentorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your students and courses effectively.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            _buildDashboardCard(
              context,
              icon: Icons.person_pin_rounded,
              title: 'Mentorship Requests',
              subtitle: 'Handle new requests from students',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationsScreen()));
              },
            ),
            const SizedBox(height: 16),
            
            _buildDashboardCard(
              context,
              icon: Icons.play_circle_fill,
              title: 'Video Courses',
              subtitle: 'Upload and track student progress',
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
              },
            ),
            const SizedBox(height: 16),
            
            _buildDashboardCard(
              context,
              icon: Icons.question_answer_rounded,
              title: 'Anonymous Queries',
              subtitle: 'Respond to student questions',
              color: Colors.greenAccent,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousQueriesScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color,
    required VoidCallback onTap
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle, 
                        style: TextStyle(color: Colors.grey[600], fontSize: 14)
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
