import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.grey[300],
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Enter email to send you a password reset email"),
            SizedBox(height: 20),
            CustomTextField(
              controller: _email,
              hint: "Enter email",
              label: "Email",
            ),
            SizedBox(height: 20),
            CustomButton(
              label: "Send Email",
              onPressed: () async {
                await _auth.sendPassResetLink(_email.text);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "An email to reset your password has been sent. Please check your inbox.")));
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}
