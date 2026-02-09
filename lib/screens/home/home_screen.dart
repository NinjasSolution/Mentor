import 'package:bgnu_mentor/screens/home/anonymous_queries_screen.dart';
import 'package:bgnu_mentor/screens/home/courses_screen.dart';
import 'package:bgnu_mentor/screens/home/student_registrations_screen.dart';
import 'package:flutter/material.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.person_add,
            title: 'Student Registrations',
            subtitle: 'View new requests and registered students',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationsScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            icon: Icons.video_library,
            title: 'Courses & Progress',
            subtitle: 'Manage courses and track student progress',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
            },
          ),
          const SizedBox(height: 16),
          _buildDashboardCard(
            context,
            icon: Icons.help_outline,
            title: 'Anonymous Queries',
            subtitle: 'Respond to anonymous student questions',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousQueriesScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
