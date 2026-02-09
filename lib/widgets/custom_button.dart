import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.color = Constants.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shadowColor: Colors.black.withOpacity(0.2),
        elevation: 5,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}