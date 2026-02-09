import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../../utils/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF000000)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF0F7FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section updated with Assets Image
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.school_rounded,
                            size: 100,
                            color: isDark ? Colors.white : Constants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    Constants.appName,
                    style: GoogleFonts.pacifico(
                      fontSize: 42,
                      color: isDark ? Colors.white : Constants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Empowering Mentorship",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Admin Section - Signup link removed
                  _buildRoleCard(
                    context,
                    label: 'Admin Login',
                    icon: Icons.admin_panel_settings_rounded,
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'admin'))),
                  ),
                  const SizedBox(height: 30),

                  // Mentor Section
                  _buildRoleCard(
                    context,
                    label: 'Mentor Login',
                    icon: Icons.psychology_rounded,
                    color: Constants.primaryColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'mentor'))),
                  ),
                  _buildSignupLink(context, 'Mentor', 'mentor', isDark),
                  const SizedBox(height: 20),

                  // Student Section
                  _buildRoleCard(
                    context,
                    label: 'Student Login',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2E7D32), // Dark Green
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(role: 'student'))),
                  ),
                  _buildSignupLink(context, 'Student', 'student', isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context, String roleLabel, String roleValue, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account? ", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13)),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(initialRole: roleValue)));
            },
            child: Text(
              'Sign up as $roleLabel',
              style: TextStyle(
                color: isDark ? Colors.white : Constants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
