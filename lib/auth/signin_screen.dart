import 'package:flutter/cupertino.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/auth/forgot_password_screen.dart';
import 'package:quran_mobile/auth/signup_screen.dart';
import 'package:quran_mobile/components/bottom_navbar.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/utils/image_strings.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/square_tile.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              Image(
                image: AssetImage(TImages.signInImage),
                width: THelperFunctions.screenWidth() * 0.5,
                height: THelperFunctions.screenHeight() * 0.4,
              ),
              SizedBox(height: 10),
              Text(
                "Welcome back! You've been missed!",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 15),
              CustomTextField(
                hint: "Enter Email",
                label: "Email",
                controller: _email,
                icon: CupertinoIcons.mail,
              ),
              SizedBox(height: 10),
              CustomTextField(
                hint: "Enter Password",
                label: "Password",
                controller: _password,
                isPassword: true,
                icon: CupertinoIcons.lock,
              ),
              SizedBox(height: 10),
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
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              CustomButton(
                label: "Sign In",
                onPressed: _login,
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SquareTile(imgPath: 'assets/Images/google-logo.png'),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Doesn't have any account?"),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () => goToSignup(context),
                    child: Text(
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
        ),
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignupScreen()),
      );

  goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavbar()),
      );

  _login() async {
    final user = await _auth.loginWithEmail(_email.text, _password.text);

    if (user != null) {
      goToHome(context);
    }
  }
}
