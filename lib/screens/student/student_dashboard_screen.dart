import 'package:bgnu_mentor/screens/community/community_screen.dart';
import 'package:bgnu_mentor/screens/student/mentor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:bgnu_mentor/screens/student/mentor_list.dart';
import 'package:bgnu_mentor/screens/messages/messages_screen.dart';
import 'package:bgnu_mentor/screens/profile/profile_screen.dart';
import 'package:bgnu_mentor/widgets/notification_bell.dart';
import 'package:bgnu_mentor/screens/student/my_mentors_screen.dart';
import 'package:bgnu_mentor/screens/student/student_tasks_screen.dart';
import 'package:bgnu_mentor/screens/home/courses_screen.dart';
import 'package:bgnu_mentor/screens/home/anonymous_queries_screen.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/mentor_model.dart';
import '../../services/mentor_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      StudentDashboardContent(onExplorePressed: () => _onItemTapped(1)),
      const MentorList(),
      const CommunityScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class StudentDashboardContent extends StatefulWidget {
  final VoidCallback onExplorePressed;
  const StudentDashboardContent({super.key, required this.onExplorePressed});

  @override
  State<StudentDashboardContent> createState() => _StudentDashboardContentState();
}

class _StudentDashboardContentState extends State<StudentDashboardContent> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final MentorService _mentorService = MentorService();
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= count) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        title: Text('Student Hub', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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
            Text('Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            
            // --- ANALYTICS ROW ---
            Row(
              children: [
                _buildStatCard(
                  'My Mentors', 
                  'mentorship_requests', 
                  'accepted', 
                  Colors.orange, 
                  Icons.group,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMentorsScreen())),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Pending Tasks', 
                  'tasks', 
                  'pending', 
                  Colors.redAccent, 
                  Icons.assignment_late,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentTasksScreen(onlyPending: true))),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // --- MENTOR SLIDER ---
            Text('Featured Mentors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: StreamBuilder<List<MentorModel>>(
                stream: _mentorService.getApprovedMentors(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final mentors = snapshot.data!;
                  if (mentors.isEmpty) return const Center(child: Text("No mentors found"));
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll(mentors.length));

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: mentors.length,
                    itemBuilder: (context, index) {
                      final mentor = mentors[index];
                      return _buildMentorSliderCard(mentor);
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Learning Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            
            _buildLearningTile(
              context,
              title: 'My Assignments',
              subtitle: 'Submit and track tasks',
              icon: Icons.task_alt_rounded,
              color: Colors.indigo,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentTasksScreen())),
            ),
            _buildLearningTile(
              context,
              title: 'Mentor Videos',
              subtitle: 'Learn from resources',
              icon: Icons.play_circle_filled_rounded,
              color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen())),
            ),
            _buildLearningTile(
              context,
              title: 'Ask Anonymous',
              subtitle: 'Get your doubts cleared',
              icon: Icons.help_center_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnonymousQueriesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorSliderCard(MentorModel mentor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MentorProfileScreen(mentor: mentor))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.psychology, size: 140, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: mentor.profilePicUrl != null ? NetworkImage(mentor.profilePicUrl!) : null,
                      child: mentor.profilePicUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mentor.name ?? 'Expert Mentor',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              mentor.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${mentor.ratingCount})',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mentor.skills.join(", "),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'View Profile',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String label, String collection, String? status, Color color, IconData icon, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Query query = FirebaseFirestore.instance.collection(collection);
    query = query.where('studentId', isEqualTo: _currentUserId);
    if (status != null) query = query.where('status', isEqualTo: status);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            bool isLoading = snapshot.connectionState == ConnectionState.waiting;
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
                  const SizedBox(height: 16),
                  isLoading 
                    ? Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 40, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))))
                    : Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLearningTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white24 : Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
