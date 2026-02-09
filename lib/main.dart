import 'package:bgnu_mentor/screens/admin/admin_dashboard_screen.dart';
import 'package:bgnu_mentor/screens/main_scaffold.dart';
import 'package:bgnu_mentor/screens/student/student_dashboard_screen.dart';
import 'package:bgnu_mentor/services/notification_service.dart';
import 'package:bgnu_mentor/services/preference_service.dart';
import 'package:bgnu_mentor/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';
import 'package:bgnu_mentor/screens/auth/role_selection_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    try {
      final notificationService = NotificationService();
      await notificationService.initFCM();
    } catch (e) {
      debugPrint("FCM Initialization suppressed: $e");
    }

  } catch (e) {
    debugPrint("Startup Initialization Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => PreferenceService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: Constants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeService.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Constants.primaryColor,
        scaffoldBackgroundColor: Constants.backgroundColor,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Constants.primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Constants.textColor),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: authService.getCurrentUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;
                NotificationService().saveToken(user.id).catchError((e) => debugPrint("Token Error: $e"));

                switch (user.role) {
                  case 'admin':
                    return const AdminDashboardScreen();
                  case 'mentor':
                    return const MainScaffold();
                  case 'student':
                    return const StudentDashboardScreen();
                  default:
                    return const RoleSelectionScreen();
                }
              }
              
              return const RoleSelectionScreen();
            },
          );
        }
        
        return const RoleSelectionScreen();
      },
    );
  }
}
