import 'package:bgnu_mentor/services/theme_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:bgnu_mentor/models/user_model.dart';
import 'package:bgnu_mentor/screens/auth/role_selection_screen.dart';
import 'package:bgnu_mentor/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditing = false;
  bool _isUploading = false;
  bool _isDeleting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(String userId, String role) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final apiService = ApiService();
      final bytes = await pickedFile.readAsBytes();
      
      String? url = await apiService.uploadProfilePic(userId, bytes, pickedFile.name);
      
      if (url == null) {
        final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('profile_pics').child(fileName);
        await ref.putData(bytes);
        url = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({'profilePicUrl': url});

      if (role == 'mentor') {
        await FirebaseFirestore.instance.collection('mentors').doc(userId).update({'profilePicUrl': url}).catchError((_){});
        await FirebaseFirestore.instance.collection('mentor_requests').doc(userId).update({'profilePicUrl': url}).catchError((_){});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showDeleteAccountDialog(AuthService authService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This action is permanent and will delete all your data. Please enter your password to confirm.'),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_isDeleting) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : () async {
                if (_passwordController.text.isEmpty) return;
                
                setDialogState(() => _isDeleting = true);
                try {
                  await authService.deleteAccount(_passwordController.text);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), 
                      (route) => false
                    );
                  }
                } catch (e) {
                  setDialogState(() => _isDeleting = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(themeService.darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: authService.getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final user = snapshot.data;
          if (user == null) return const Center(child: Text('User data not found'));

          if (!_isEditing) _nameController.text = user.name;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        backgroundImage: user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty 
                            ? NetworkImage(user.profilePicUrl!) 
                            : null,
                        child: (user.profilePicUrl == null || user.profilePicUrl!.isEmpty) 
                            ? const Icon(Icons.person, size: 85, color: Colors.blueAccent) 
                            : null,
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickAndUploadImage(user.id, user.role),
                          child: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            radius: 20,
                            child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  title: 'Name',
                  content: _isEditing
                      ? TextField(controller: _nameController, decoration: const InputDecoration(border: OutlineInputBorder()))
                      : Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(title: 'Email', content: Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Role',
                  content: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                // Theme Toggle switch
                _buildInfoCard(
                  title: 'Theme',
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(themeService.darkMode ? 'Dark Mode' : 'Light Mode', style: const TextStyle(fontSize: 16)),
                      Switch(
                        value: themeService.darkMode,
                        onChanged: (val) => themeService.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('users').doc(user.id).update({'name': _nameController.text.trim()});
                          setState(() => _isEditing = false);
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                if (!_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () async {
                        await authService.logout();
                        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                  if (user.role != 'admin') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => _showDeleteAccountDialog(authService),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Delete Account Permanently'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(height: 8), content]),
    );
  }
}
