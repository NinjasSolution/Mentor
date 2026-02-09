import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/services/course_service.dart';
import 'package:bgnu_mentor/models/course_model.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CourseService _courseService = CourseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  void _openVideoExternally(CourseModel course, String role) async {
    String url = course.videoUrl;

    if (role == 'student') {
      await _courseService.updateVideoProgress(_currentUserId, course.id, 0.5);
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch video link.')));
      }
    }
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload New Video'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Video URL (YouTube/Drive link)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty && _urlController.text.isNotEmpty) {
                await _courseService.uploadCourse(_currentUserId, _titleController.text.trim(), _descController.text.trim(), _urlController.text.trim());
                _titleController.clear(); _descController.clear(); _urlController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _showWatchersList(CourseModel course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Engagement: ${course.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: course.watchedBy.isEmpty 
                ? const Center(child: Text('No students have started this video yet.'))
                : ListView.builder(
                    itemCount: course.watchedBy.length,
                    itemBuilder: (context, index) {
                      final studentId = course.watchedBy[index];
                      return StreamBuilder<double>(
                        stream: _courseService.getVideoProgress(studentId, course.id),
                        builder: (context, progressSnapshot) {
                          final progress = progressSnapshot.data ?? 0.0;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) return const SizedBox();
                              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: data?['profilePicUrl'] != null ? NetworkImage(data!['profilePicUrl']) : null,
                                  child: data?['profilePicUrl'] == null ? const Icon(Icons.person) : null,
                                ),
                                title: Text(data?['name'] ?? 'Unknown'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], color: progress >= 0.9 ? Colors.green : Colors.blue),
                                    Text(progress >= 0.5 ? 'Watched / In-Progress' : 'Just Started', style: const TextStyle(fontSize: 10)),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      future: Provider.of<AuthService>(context, listen: false).getCurrentUserData(),
      builder: (context, userSnapshot) {
        final String role = userSnapshot.data?.role ?? 'student';

        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.grey[50],
          appBar: AppBar(
            title: const Text('Video Lessons'),
            elevation: 0,
            actions: [
              if (role == 'mentor') IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showAddCourseDialog),
            ],
          ),
          body: StreamBuilder<List<CourseModel>>(
            stream: role == 'mentor' 
              ? _courseService.getMentorCourses(_currentUserId) 
              : _courseService.getStudentConnectedCourses(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(isDark);

              final courses = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                            child: const Icon(Icons.play_circle_filled, color: Colors.blue, size: 30),
                          ),
                          title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(course.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (role == 'mentor')
                                TextButton.icon(
                                  onPressed: () => _showWatchersList(course),
                                  icon: const Icon(Icons.analytics_outlined),
                                  label: Text('${course.watchedBy.length} Views'),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.ondemand_video_rounded, color: Colors.blue, size: 16),
                                    SizedBox(width: 4),
                                    Text('Shared by Mentor', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ElevatedButton(
                                onPressed: () => _openVideoExternally(course, role),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(role == 'student' ? 'Watch Video' : 'Preview Video'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No video lessons found.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
