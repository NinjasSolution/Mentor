import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
              ),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school_rounded,
                      size: 100,
                      color: Constants.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _controller,
              child: Text(
                Constants.appName,
                style: GoogleFonts.pacifico(
                  fontSize: 42,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
