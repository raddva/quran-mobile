import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.isDisabled = false,
    this.icon,
    this.validator,
  });

  final String hint;
  final String label;
  final bool isPassword;
  final bool isDisabled;
  final TextEditingController? controller;
  final IconData? icon;
  final String? Function(String?)? validator;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;
  final bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        readOnly: widget.isDisabled ? _isEnabled : false,
        obscureText: widget.isPassword ? _isObscure : false,
        controller: widget.controller,
        validator: widget.validator ?? _defaultValidator,
        decoration: InputDecoration(
          hintText: widget.hint,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.green),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red),
          ),
          fillColor: Colors.white,
          filled: true,
          label: Text(
            widget.label,
            style: TextStyle(color: Colors.green),
          ),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: Colors.green,
                )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: Colors.green,
                  ),
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

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "This field cannot be empty";
    }
    if (widget.label == "Email" && !EmailValidator.validate(value)) {
      return "Enter a valid email";
    }
    if (widget.isPassword && value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }
}
