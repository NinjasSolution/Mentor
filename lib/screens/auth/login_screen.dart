import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../admin/admin_dashboard_screen.dart';
import '../main_scaffold.dart';
import '../student/student_dashboard_screen.dart';
import 'signup_screen.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  final String? role; 
  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      UserModel? user = await authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (user != null) {
        if (user.role == 'mentor') {
          if (user.status == 'pending') {
            _showErrorSnackBar('Your mentor account is pending approval');
            return;
          } else if (user.status == 'rejected') {
            _showErrorSnackBar('Your mentor account was rejected');
            return;
          }
        }

        Widget dashboard;
        if (user.role == 'admin') {
          dashboard = const AdminDashboardScreen();
        } else if (user.role == 'mentor') {
          dashboard = const MainScaffold();
        } else {
          dashboard = const StudentDashboardScreen();
        }

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => dashboard),
            (route) => false
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Login failed');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Reset Password', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive password reset instructions.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: 'Email',
              controller: resetEmailController,
              icon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;
              try {
                await Provider.of<AuthService>(context, listen: false).resetPassword(resetEmailController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent! Check your inbox.'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending reset email.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdmin = widget.role == 'admin';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('${widget.role?.toUpperCase() ?? ""} Login'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Constants.primaryColor),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF000000)]
              : [Colors.white, const Color(0xFFF0F7FF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1), 
                            blurRadius: 20
                          )
                        ],
                      ),
                      child: Icon(Icons.school_rounded, size: 70, color: isDark ? Colors.white : Constants.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.roboto(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Constants.primaryColor
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to continue your journey',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    hintText: 'Email Address',
                    controller: emailController,
                    icon: Icons.email_outlined,
                    validator: (v) => v!.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: 'Password',
                    controller: passwordController,
                    obscureText: true,
                    icon: Icons.lock_outline,
                    validator: (v) => v!.isEmpty ? 'Enter password' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?', 
                        style: TextStyle(color: isDark ? Colors.white70 : Constants.primaryColor)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Login',
                            onPressed: _loginUser,
                          ),
                        ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(initialRole: widget.role ?? 'student'))),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: isDark ? Colors.white : Constants.primaryColor, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
