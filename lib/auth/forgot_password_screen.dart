import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:email_validator/email_validator.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.green,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.green,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLargeScreen)
                  Card(
                    elevation: 8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: THelperFunctions.screenWidth() * 0.5,
                      height: THelperFunctions.screenHeight() * 0.4,
                      padding: const EdgeInsets.all(20),
                      child: _buildBodyElements(),
                    ),
                  )
                else
                  _buildBodyElements(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyElements() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your email to receive a password reset link",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _email,
              hint: "Enter your email",
              label: "Email",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Email cannot be empty";
                }
                if (!EmailValidator.validate(value)) {
                  return "Enter a valid email";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: "Send Email",
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _isLoading = true);

                String email = _email.text.trim();

                try {
                  await _auth.sendPassResetLink(email);

                  if (mounted) {
                    showSuccessAlert(context,
                        "A password reset email has been sent. Please check your inbox.");

                    await Future.delayed(const Duration(seconds: 2));

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    showCustomAlertDialog(
                        context, "Failed", "An unexpected error occurred.");
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
