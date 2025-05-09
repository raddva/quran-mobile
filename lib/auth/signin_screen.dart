import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/auth/forgot_password_screen.dart';
import 'package:quran_mobile/auth/signup_screen.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/utils/image_strings.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/square_tile.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      AuthResult result =
          await _auth.loginWithEmail(_email.text, _password.text);
      setState(() => _isLoading = false);

      if (result.user != null) {
        final user = result.user;

        final adminDoc = await FirebaseFirestore.instance
            .collection('admin')
            .doc(user?.uid)
            .get();

        if (adminDoc.exists) {
          Get.offNamed('/admin');
        } else {
          Get.offNamed('/home');
        }
      } else {
        showCustomAlertDialog(
          context,
          "Login Failed",
          result.errors?.join("\n") ?? "Unknown error",
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showCustomAlertDialog(
        context,
        "Login Failed",
        "An unexpected error occurred.",
      );
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: isLargeScreen
              ? Card(
                  margin: EdgeInsets.all(40),
                  elevation: 10,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            TImages.signInImage,
                            fit: BoxFit.fill,
                          ),
                        ),
                        VerticalDivider(thickness: 1, color: Colors.green[700]),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: _buildLoginForm(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Image.asset(
                        TImages.signInImage,
                        width: THelperFunctions.screenWidth() * 0.5,
                        height: THelperFunctions.screenHeight() * 0.4,
                      ),
                      _buildLoginForm(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // const SizedBox(height: 10),
          Text(
            "Welcome back! You've been missed!",
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          CustomTextField(
            hint: "Enter Email",
            label: "Email",
            controller: _email,
            icon: CupertinoIcons.mail,
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
          const SizedBox(height: 10),
          CustomTextField(
            hint: "Enter Password",
            label: "Password",
            controller: _password,
            isPassword: true,
            icon: CupertinoIcons.lock,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password cannot be empty";
              }
              if (value.length < 6) {
                return "Password must be at least 6 characters long";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ));
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _isLoading
              ? const CircularProgressIndicator()
              : CustomButton(
                  label: "Sign In",
                  onPressed: _login,
                ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.green[400],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Or continue with',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () async {
              try {
                final userCredential = await _auth.loginWithGoogle();
                final user = userCredential?.user;

                if (user != null) {
                  final adminDoc = await FirebaseFirestore.instance
                      .collection('admins')
                      .doc(user.uid)
                      .get();

                  if (adminDoc.exists) {
                    Get.offNamed('/admin-dashboard');
                  } else {
                    Get.offNamed('/home');
                  }
                }
              } catch (e) {
                showCustomAlertDialog(
                  context,
                  "Google Sign-In Failed",
                  e.toString(),
                );
              }
            },
            child: SquareTile(imgPath: 'assets/Images/google-logo.png'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Doesn't have an account?"),
              const SizedBox(width: 4),
              InkWell(
                onTap: _goToSignup,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
