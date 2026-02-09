import 'package:bgnu_mentor/screens/home/anonymous_queries_screen.dart';
import 'package:bgnu_mentor/screens/home/courses_screen.dart';
import 'package:bgnu_mentor/screens/home/student_registrations_screen.dart';
import 'package:bgnu_mentor/screens/users/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:bgnu_mentor/widgets/notification_bell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: Text('Mentor Central', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        actions: const [
          NotificationBell(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            
            // --- ANALYTICS ROW 1 ---
            Row(
              children: [
                _buildStatCard(
                  'Active Students', 
                  'mentorship_requests', 
                  'accepted', 
                  Colors.blue, 
                  Icons.people,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen(showAllStudents: true))),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Tasks to Review', 
                  'tasks', 
                  'submitted', 
                  Colors.orange, 
                  Icons.rate_review_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen(filterStatus: 'submitted'))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // --- ANALYTICS ROW 2 ---
            Row(
              children: [
                _buildStatCard(
                  'Awaiting Student Work', 
                  'tasks', 
                  'pending', 
                  Colors.redAccent, 
                  Icons.assignment_late_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen(filterStatus: 'pending'))),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'New Requests', 
                  'mentorship_requests', 
                  'pending', 
                  Colors.purple, 
                  Icons.person_add,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationsScreen())),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            
            _buildActionTile(
              context,
              icon: Icons.group_add_rounded,
              title: 'Manage Enrollments',
              subtitle: 'Review student applications',
              color: Colors.blueAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationsScreen())),
            ),
            _buildActionTile(
              context,
              icon: Icons.video_library_rounded,
              title: 'Course Content',
              subtitle: 'Upload and manage videos',
              color: Colors.orangeAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen())),
            ),
            _buildActionTile(
              context,
              icon: Icons.forum_rounded,
              title: 'Student Q&A',
              subtitle: 'Reply to anonymous queries',
              color: Colors.greenAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousQueriesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String collection, String? status, Color color, IconData icon, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Query query = FirebaseFirestore.instance.collection(collection);
    
    if (collection == 'tasks' || collection == 'mentorship_requests') {
      query = query.where('mentorId', isEqualTo: _currentUserId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            bool isLoading = snapshot.connectionState == ConnectionState.waiting;
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 12),
                  isLoading 
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(width: 40, height: 24, color: Colors.white),
                      )
                    : Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
