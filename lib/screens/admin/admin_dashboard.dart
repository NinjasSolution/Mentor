import 'package:bgnu_mentor/models/mentor_model.dart';
import 'package:bgnu_mentor/models/post_model.dart';
import 'package:bgnu_mentor/models/task_model.dart';
import 'package:bgnu_mentor/models/user_model.dart';
import 'package:bgnu_mentor/services/api_service.dart';
import 'package:bgnu_mentor/services/theme_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import 'mentor_requests.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isSyncing = false;

  Future<void> _syncExistingData() async {
    setState(() => _isSyncing = true);
    final apiService = ApiService();
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Sync All Users from Firestore 'users' collection
      final userSnap = await firestore.collection('users').get();
      for (var doc in userSnap.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        
        MentorModel? mentorDetails;
        if (user.role == 'mentor') {
          // Fetch full profile if they are a mentor
          final mDoc = await firestore.collection('mentors').doc(user.id).get();
          if (mDoc.exists) {
            mentorDetails = MentorModel.fromMap(mDoc.data()!);
          } else {
            final rDoc = await firestore.collection('mentor_requests').doc(user.id).get();
            if (rDoc.exists) {
              mentorDetails = MentorModel.fromMap(rDoc.data()!);
            }
          }
        }
        
        // This method now correctly sends students to 'students' table and mentors to 'mentors' table
        await apiService.syncUserByRole(user, mentorDetails: mentorDetails);
      }

      // 2. Sync Tasks
      final taskSnap = await firestore.collection('tasks').get();
      for (var doc in taskSnap.docs) {
        final task = TaskModel.fromMap(doc.data(), doc.id);
        await apiService.syncTaskToMySQL(task);
      }

      // 3. Sync Posts
      final postSnap = await firestore.collection('community_posts').get();
      for (var doc in postSnap.docs) {
        final post = PostModel.fromMap(doc.data(), doc.id);
        await apiService.syncPostToMySQL(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database Sync Complete! All Students, Mentors & Tasks are now in MySQL.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Central'),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : null,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manage Platform', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            
            _buildControlCard(
              context,
              title: 'Mentor Requests',
              subtitle: 'Approve or Reject applications',
              icon: Icons.pending_actions,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorRequests())),
            ),
            
            const SizedBox(height: 20),

            // NEW SYNC SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_sync, size: 40, color: Colors.green),
                  const SizedBox(height: 12),
                  const Text(
                    'MySQL Separate Sync',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Syncs Students to `students` table and Mentors to `mentors` table.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _isSyncing 
                    ? const CircularProgressIndicator(color: Colors.green)
                    : ElevatedButton.icon(
                        onPressed: _syncExistingData,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Migration Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
