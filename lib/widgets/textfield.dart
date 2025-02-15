import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.isDisabled = false,
    this.icon,
  });

  final String hint;
  final String label;
  final bool isPassword;
  final bool isDisabled;
  final TextEditingController? controller;
  final IconData? icon;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        readOnly: widget.isDisabled ? _isEnabled : false,
        obscureText: widget.isPassword ? _isObscure : false,
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hint,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade400),
          ),
          fillColor: Colors.green[50],
          filled: true,
          label: Text(widget.label),
          prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_isObscure
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
