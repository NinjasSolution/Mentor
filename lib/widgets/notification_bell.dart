import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/student/student_tasks_screen.dart';
import '../screens/home/student_registrations_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/student/my_mentors_screen.dart';
import '../screens/profile/profile_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final NotificationService _notifService = NotificationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _notifService.getNotifications(userId),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.where((doc) => doc['isRead'] == false).length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_none_rounded, 
                size: 28,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => _showNotificationsDialog(context, snapshot.data?.docs ?? [], userId),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context, List<QueryDocumentSnapshot> docs, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 60, color: isDark ? Colors.white10 : Colors.grey[300]),
                          const SizedBox(height: 10),
                          const Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final bool isRead = data['isRead'] ?? false;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: isRead 
                                ? (isDark ? Colors.white10 : Colors.grey[100]) 
                                : Colors.blue[50],
                            child: Icon(
                              _getIconForType(data['type']),
                              color: isRead ? Colors.grey : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            data['title'] ?? 'Notification', 
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold, 
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black,
                            )
                          ),
                          subtitle: Text(data['body'] ?? '', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13)),
                          trailing: !isRead ? const CircleAvatar(radius: 4, backgroundColor: Colors.blue) : null,
                          onTap: () {
                            NotificationService().markAsRead(userId, docs[index].id);
                            _handleNavigation(context, data['type']);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'chat': return Icons.message_rounded;
      case 'mentorship_request': return Icons.person_add_rounded;
      case 'mentorship_update': return Icons.verified_user_rounded;
      case 'task': return Icons.assignment_rounded;
      case 'task_submission': return Icons.upload_file_rounded;
      case 'role_update': return Icons.security_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  void _handleNavigation(BuildContext context, String? type) {
    Navigator.pop(context); // Close bottom sheet
    
    switch (type) {
      case 'chat':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
        break;
      case 'task':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentTasksScreen()));
        break;
      case 'task_submission':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
        break;
      case 'mentorship_request':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationsScreen()));
        break;
      case 'mentorship_update':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyMentorsScreen()));
        break;
      case 'role_update':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      default:
        // Do nothing or stay on current page
        break;
    }
  }
}
