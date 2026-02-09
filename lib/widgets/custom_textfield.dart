import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.icon,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
        prefixIcon: widget.icon != null ? Icon(widget.icon, color: isDark ? Colors.white70 : Colors.grey[700]) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
