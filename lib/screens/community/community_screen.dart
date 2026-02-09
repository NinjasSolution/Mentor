import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/preference_service.dart';
import '../../services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  // Removed 'Resource' from filters
  final List<String> _filters = ['All', 'Announcement', 'Discussion', 'Event'];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final prefService = Provider.of<PreferenceService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String selectedFilter = prefService.communityFilter;
    if (!_filters.contains(selectedFilter)) {
      selectedFilter = 'All';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Community Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark, selectedFilter, prefService),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _communityService.getPosts(type: selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return _buildModernPostCard(posts[index], authService.currentUser?.uid ?? '', isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, String selectedFilter, PreferenceService prefService) {
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedFilter == _filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => prefService.setCommunityFilter(_filters[index]),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white10 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernPostCard(PostModel post, String currentUserId, bool isDark) {
    bool isLiked = post.likes.contains(currentUserId);
    bool isAuthor = post.authorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorProfilePic != null ? NetworkImage(post.authorProfilePic!) : null,
                  child: post.authorProfilePic == null ? const Icon(Icons.person, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 6),
                          _buildRoleBadge(post.authorRole),
                        ],
                      ),
                      Text(
                        '${DateFormat('MMM dd').format(post.timestamp)} • ${post.type}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(post.id);
                    } else if (value == 'report') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post reported.')));
                    }
                  },
                  itemBuilder: (context) => [
                    if (isAuthor)
                      const PopupMenuItem(value: 'delete', child: Text('Delete Post', style: TextStyle(color: Colors.red))),
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              post.content,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(height: 200, color: isDark ? Colors.white10 : Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: post.likes.length.toString(),
                  color: isLiked ? Colors.red : Colors.grey,
                  onTap: () => _communityService.likePost(post.id, currentUserId, isLiked),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.commentCount.toString(),
                  color: Colors.grey,
                  onTap: () => _showComments(post.id, isDark),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.grey,
                  onTap: () => _sharePost(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _communityService.deletePost(postId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showComments(String postId, bool isDark) {
    final commentController = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data = comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['authorProfilePic'] != null ? NetworkImage(data['authorProfilePic']) : null,
                          child: data['authorProfilePic'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(data['authorName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(data['content'] ?? ''),
                        trailing: Text(
                          data['timestamp'] != null ? DateFormat('MMM dd').format((data['timestamp'] as Timestamp).toDate()) : '',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;
                      final user = await authService.getCurrentUserData();
                      if (user == null) return;

                      await FirebaseFirestore.instance.collection('community_posts').doc(postId).collection('comments').add({
                        'authorId': user.id,
                        'authorName': user.name,
                        'authorProfilePic': user.profilePicUrl,
                        'content': commentController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      
                      await FirebaseFirestore.instance.collection('community_posts').doc(postId).update({
                        'commentCount': FieldValue.increment(1),
                      });
                      
                      commentController.clear();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = role == 'admin' ? Colors.red : (role == 'mentor' ? Colors.blue : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  void _sharePost(PostModel post) {
    String text = 'Check out this post from ${post.authorName} in BGNU Mentor Community:\n\n'
        '${post.content}\n\n'
        'Read more on BGNU Mentor App!';
    Share.share(text);
  }

  void _showCreatePostDialog(BuildContext context) {
    final contentController = TextEditingController();
    String selectedType = 'Discussion';
    XFile? pickedImage;
    bool isPosting = false;
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: _filters.where((f) => f != 'All').map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) => setModalState(() => selectedType = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                if (pickedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb 
                          ? Image.network(pickedImage!.path, height: 150, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(pickedImage!.path), height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 5, right: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setModalState(() => pickedImage = null),
                          ),
                        ),
                      )
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (img != null) setModalState(() => pickedImage = img);
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Add Image'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isPosting ? null : () async {
                      if (contentController.text.trim().isEmpty) return;
                      
                      setModalState(() => isPosting = true);
                      
                      try {
                        final userData = await authService.getCurrentUserData();
                        if (userData == null) return;

                        String? uploadedImageUrl;
                        if (pickedImage != null) {
                          // Upload image to domain database (API) instead of Firebase Storage
                          final bytes = await pickedImage!.readAsBytes();
                          uploadedImageUrl = await apiService.uploadTaskFile(
                            userData.id + DateTime.now().millisecondsSinceEpoch.toString(), 
                            bytes, 
                            pickedImage!.name
                          );
                        }

                        final newPost = PostModel(
                          id: '',
                          authorId: userData.id,
                          authorName: userData.name,
                          authorProfilePic: userData.profilePicUrl,
                          authorRole: userData.role,
                          content: contentController.text.trim(),
                          imageUrl: uploadedImageUrl,
                          type: selectedType.toLowerCase(),
                          timestamp: DateTime.now(),
                          likes: [],
                          commentCount: 0,
                        );

                        await _communityService.createPost(newPost);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModalState(() => isPosting = false);
                        debugPrint('Post Error: $e');
                      }
                    },
                    child: isPosting ? const CircularProgressIndicator(color: Colors.white) : const Text('Post to Community'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Be the first to start a conversation!', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ],
      ),
    );
  }
}
