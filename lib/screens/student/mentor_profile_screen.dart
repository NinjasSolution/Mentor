import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/mentor_model.dart';
import '../../services/mentor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../messages/messages_screen.dart';
import '../../widgets/full_screen_image_view.dart';

class MentorProfileScreen extends StatefulWidget {
  final MentorModel mentor;

  const MentorProfileScreen({Key? key, required this.mentor}) : super(key: key);

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final _messageController = TextEditingController();
  final _reviewController = TextEditingController();
  final MentorService _mentorService = MentorService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _showRatingDialog() {
    double selectedRating = 5.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Mentor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => selectedRating = rating,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _mentorService.rateMentor(widget.mentor.userId, _currentUserId, selectedRating, _reviewController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mentorship Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Explain briefly why you want to connect with this mentor.'),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your message here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _isSending ? null : _sendRequest,
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message.')));
      return;
    }
    setState(() => _isSending = true);
    try {
      await _mentorService.sendMentorshipRequest(_currentUserId, widget.mentor.userId, _messageController.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            backgroundColor: isDark ? const Color(0xFF121212) : primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.mentor.name ?? 'Mentor Profile',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.mentor.bannerUrl != null && widget.mentor.bannerUrl!.isNotEmpty)
                    Image.network(widget.mentor.bannerUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                            ? [const Color(0xFF232526), const Color(0xFF414345)]
                            : [primaryColor.withOpacity(0.8), primaryColor],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.school_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          isDark ? Colors.black : Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFFF8F9FA),
              ),
              child: Column(
                children: [
                  // Profile Section Overlap
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.mentor.profilePicUrl != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrl: widget.mentor.profilePicUrl!)));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: widget.mentor.profilePicUrl != null ? NetworkImage(widget.mentor.profilePicUrl!) : null,
                              child: widget.mentor.profilePicUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.mentor.name ?? 'Expert Mentor', 
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.mentor.averageRating.toStringAsFixed(1), 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                            Text(
                              ' (${widget.mentor.ratingCount} reviews)', 
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection('About', widget.mentor.bio.isEmpty ? "No bio available." : widget.mentor.bio, isDark),
                        const SizedBox(height: 25),
                        _buildSkillsSection(widget.mentor.skills, isDark),
                        const SizedBox(height: 30),
                        
                        StreamBuilder<DocumentSnapshot>(
                          stream: _mentorService.getRequestStatus(_currentUserId, widget.mentor.userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            final bool isEnrolled = snapshot.data!.exists && (snapshot.data!.data() as Map<String, dynamic>?)?['status'] == 'accepted';

                            return Column(
                              children: [
                                if (isEnrolled) ...[
                                  _buildActionButton(
                                    label: 'Chat with Mentor',
                                    icon: Icons.chat_bubble_rounded,
                                    color: Colors.green,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverId: widget.mentor.userId, receiverName: widget.mentor.name ?? 'Mentor'))),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    label: 'Rate Mentor',
                                    icon: Icons.star_border_rounded,
                                    color: Colors.amber[800]!,
                                    onTap: _showRatingDialog,
                                  ),
                                ] else ...[
                                  _buildMentorshipStatus(snapshot, isDark),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
      ],
    );
  }

  Widget _buildSkillsSection(List<String> skills, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expertise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Text(skill, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMentorshipStatus(AsyncSnapshot<DocumentSnapshot> snapshot, bool isDark) {
    final bool hasRequest = snapshot.data!.exists;
    String status = '';
    
    if (hasRequest) {
      final data = snapshot.data!.data() as Map<String, dynamic>?;
      status = data?['status'] ?? '';
    }

    if (hasRequest && status == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Center(child: Text('Request Pending Approval', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
      );
    } else {
      return _buildActionButton(
        label: 'Send Mentorship Request',
        icon: Icons.send_rounded,
        color: Theme.of(context).primaryColor,
        onTap: _showRequestDialog,
      );
    }
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
