import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'api_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _apiService = ApiService();
  final String _collection = 'community_posts';

  Stream<List<PostModel>> getPosts({String? type}) {
    Query query = _firestore.collection(_collection).orderBy('timestamp', descending: true);
    if (type != null && type != 'All') {
      query = query.where('type', isEqualTo: type.toLowerCase());
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> createPost(PostModel post) async {
    final docRef = await _firestore.collection(_collection).add(post.toMap());
    
    // Sync to MySQL
    final newPost = PostModel(
      id: docRef.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorProfilePic: post.authorProfilePic,
      authorRole: post.authorRole,
      content: post.content,
      imageUrl: post.imageUrl,
      type: post.type,
      timestamp: post.timestamp,
      likes: post.likes,
      commentCount: post.commentCount,
    );
    _apiService.syncPostToMySQL(newPost);
  }

  Future<void> likePost(String postId, String userId, bool isLiked) async {
    if (isLiked) {
      await _firestore.collection(_collection).doc(postId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await _firestore.collection(_collection).doc(postId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection(_collection).doc(postId).delete();
  }
}
