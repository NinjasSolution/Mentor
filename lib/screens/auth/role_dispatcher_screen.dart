import 'package:bgnu_mentor/models/user_model.dart';
import 'package:bgnu_mentor/screens/admin/admin_dashboard_screen.dart';
import 'package:bgnu_mentor/screens/main_scaffold.dart';
import 'package:bgnu_mentor/screens/student/student_dashboard_screen.dart';
import 'package:bgnu_mentor/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoleDispatcherScreen extends StatefulWidget {
  const RoleDispatcherScreen({super.key});

  @override
  State<RoleDispatcherScreen> createState() => _RoleDispatcherScreenState();
}

class _RoleDispatcherScreenState extends State<RoleDispatcherScreen> {
  @override
  void initState() {
    super.initState();
    _dispatchUser();
  }

  Future<void> _dispatchUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final UserModel? user = await authService.getCurrentUserData();

    if (user != null) {
      switch (user.role) {
        case 'mentor':
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScaffold()));
          break;
        case 'student':
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
          break;
        case 'admin':
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          break;
        default:
          // Handle unknown role or logout
          authService.logout();
          break;
      }
    } else {
      // Handle user data not found or logout
      authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
