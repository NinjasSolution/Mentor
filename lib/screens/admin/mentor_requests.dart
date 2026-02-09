import 'package:bgnu_mentor/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mentor_model.dart';
import '../../services/mentor_service.dart';

class MentorRequests extends StatefulWidget {
  const MentorRequests({super.key});

  @override
  State<MentorRequests> createState() => _MentorRequestsState();
}

class _MentorRequestsState extends State<MentorRequests> {
  final MentorService _mentorService = MentorService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        appBar: AppBar(
          title: const Text('Mentor Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Active Mentors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingList(isDark),
            _buildActiveList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(bool isDark) {
    return StreamBuilder<List<MentorModel>>(
      stream: _mentorService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No pending requests.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildMentorCard(snapshot.data![index], true, isDark),
        );
      },
    );
  }

  Widget _buildActiveList(bool isDark) {
    return StreamBuilder<List<MentorModel>>(
      stream: _mentorService.getApprovedMentors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No active mentors.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _buildMentorCard(snapshot.data![index], false, isDark),
        );
      },
    );
  }

  Widget _buildMentorCard(MentorModel mentor, bool isPending, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage: mentor.profilePicUrl != null ? NetworkImage(mentor.profilePicUrl!) : null,
          child: mentor.profilePicUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(mentor.name ?? 'New Mentor', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(mentor.skills.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildInfoRow(Icons.work, 'Experience', mentor.experience),
                _buildInfoRow(Icons.description, 'Bio', mentor.bio),
                // Only show phone if it's not null and not empty
                if (mentor.phone != null && mentor.phone!.trim().isNotEmpty) 
                  _buildInfoRow(Icons.phone, 'Phone', mentor.phone!),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (mentor.linkedinUrl != null && mentor.linkedinUrl!.isNotEmpty) 
                      _socialIcon(FontAwesomeIcons.linkedin, Colors.blue, mentor.linkedinUrl!),
                    if (mentor.githubUrl != null && mentor.githubUrl!.isNotEmpty) 
                      _socialIcon(FontAwesomeIcons.github, isDark ? Colors.white : Colors.black, mentor.githubUrl!),
                    if (mentor.youtubeUrl != null && mentor.youtubeUrl!.isNotEmpty) 
                      _socialIcon(FontAwesomeIcons.youtube, Colors.red, mentor.youtubeUrl!),
                    if (!isPending)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverId: mentor.userId, receiverName: mentor.name ?? 'Mentor', receiverRole: 'mentor'))),
                        tooltip: 'Message Mentor',
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _mentorService.approveMentor(mentor.userId),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _mentorService.rejectMentor(mentor.userId),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _mentorService.rejectMentor(mentor.userId),
                      icon: const Icon(Icons.block),
                      label: const Text('Deactivate Mentor'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: RichText(text: TextSpan(
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ]
          ))),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, String url) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 24),
      onPressed: () => launchUrl(Uri.parse(url)),
    );
  }
}
