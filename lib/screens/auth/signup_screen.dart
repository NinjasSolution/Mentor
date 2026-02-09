import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SignupScreen extends StatefulWidget {
  final String initialRole;
  const SignupScreen({super.key, this.initialRole = 'student'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController githubController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  late String _selectedRole;
  bool _isMentor = false;
  bool _isLoading = false;

  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Prevent navigating to admin signup
    if (widget.initialRole == 'admin') {
      _selectedRole = 'student';
    } else {
      _selectedRole = widget.initialRole;
    }
    _isMentor = _selectedRole == 'mentor';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
      return 'Include Uppercase, Lowercase, Number & Special Character';
    }
    return null;
  }

  Future<void> _signupUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
      return;
    }

    if (_isMentor && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a profile picture'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();

    try {
      var userModel = await authService.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        _selectedRole,
      );

      String? finalPicUrl;

      if (_isMentor && _pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        finalPicUrl = await apiService.uploadProfilePic(userModel.id, bytes, _pickedImage!.name);
        
        if (finalPicUrl == null) {
           final ref = FirebaseStorage.instance.ref().child('mentor_pics/${userModel.id}.jpg');
           if (kIsWeb) {
             await ref.putData(bytes);
           } else {
             await ref.putFile(File(_pickedImage!.path));
           }
           finalPicUrl = await ref.getDownloadURL();
        }

        List<String> skills = skillsController.text.split(',').map((s) => s.trim()).toList();
        
        await FirebaseFirestore.instance.collection('mentor_requests').doc(userModel.id).set({
          'userId': userModel.id,
          'name': nameController.text.trim(),
          'skills': skills,
          'experience': experienceController.text,
          'bio': bioController.text,
          'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          'profilePicUrl': finalPicUrl,
          'linkedinUrl': linkedinController.text.trim(),
          'githubUrl': githubController.text.trim(),
          'youtubeUrl': youtubeController.text.trim(),
          'status': 'pending',
          'bannerUrl': '', // Placeholder for banner
        });
        
        userModel.status = 'pending';
        await apiService.syncUser(userModel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup successful! Please login.'), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup as ${_selectedRole.toUpperCase()}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(hintText: 'Name', controller: nameController, icon: Icons.person, validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              CustomTextField(hintText: 'Email', controller: emailController, icon: Icons.email, validator: (v) => v!.isEmpty ? 'Email is required' : null),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Password', 
                controller: passwordController, 
                obscureText: true, 
                icon: Icons.lock, 
                validator: _validatePassword
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Confirm Password', 
                controller: confirmPasswordController, 
                obscureText: true, 
                icon: Icons.lock_clock, 
                validator: (v) => v!.isEmpty ? 'Please confirm your password' : null
              ),
              const SizedBox(height: 16),

              if (_isMentor) ...[
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo), label: const Text('Select Profile Pic'))),
                    const SizedBox(width: 10),
                    if (_pickedImage != null) const Icon(Icons.check_circle, color: Colors.green) else const Text('Required', style: TextStyle(color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(hintText: 'Skills (e.g. Flutter, React)', controller: skillsController, icon: Icons.code, validator: (v) => v!.isEmpty ? 'Skills are required' : null),
                const SizedBox(height: 16),
                CustomTextField(hintText: 'Experience (years)', controller: experienceController, icon: Icons.work, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                CustomTextField(hintText: 'Bio', controller: bioController, icon: Icons.description, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                CustomTextField(hintText: 'Phone Number (Optional)', controller: phoneController, icon: Icons.phone),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Social Links (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CustomTextField(hintText: 'LinkedIn Profile URL', controller: linkedinController, icon: Icons.link),
                const SizedBox(height: 12),
                CustomTextField(hintText: 'GitHub URL', controller: githubController, icon: Icons.code_off),
                const SizedBox(height: 12),
                CustomTextField(hintText: 'YouTube Channel URL', controller: youtubeController, icon: Icons.play_circle),
                const SizedBox(height: 20),
              ],

              _isLoading 
                ? const CircularProgressIndicator() 
                : CustomButton(text: 'Signup', onPressed: _signupUser),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Already have an account? Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    skillsController.dispose();
    experienceController.dispose();
    bioController.dispose();
    phoneController.dispose();
    linkedinController.dispose();
    githubController.dispose();
    youtubeController.dispose();
    super.dispose();
  }
}
