import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:quran_mobile/screens/home.dart';
import 'package:quran_mobile/utils/helpers.dart';
import 'package:quran_mobile/utils/image_strings.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/widgets/wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 20),
              Image(
                image: AssetImage(TImages.signUpImage),
                width: THelperFunctions.screenWidth() * 0.5,
                height: THelperFunctions.screenHeight() * 0.4,
              ),
              SizedBox(height: 10),
              Text(
                "Hello, Please Register to Continue.",
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 15),
              CustomTextField(
                hint: "Enter Name",
                label: "Name",
                controller: _name,
                icon: CupertinoIcons.person,
              ),
              SizedBox(height: 10),
              CustomTextField(
                hint: "Enter Email",
                label: "Email",
                controller: _email,
                icon: CupertinoIcons.mail,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                hint: "Enter Password",
                label: "Password",
                controller: _password,
                isPassword: true,
                icon: CupertinoIcons.lock,
              ),
              SizedBox(height: 15),
              CustomButton(
                label: "Sign Up",
                onPressed: _signup,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  SizedBox(width: 4),
                  InkWell(
                    onTap: () => goToLogin(context),
                    child: Text(
                      'Sign In',
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

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

  goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

  _signup() async {
    User? user = await _auth.createUserWithEmail(
        _name.text, _email.text, _password.text);

    if (user != null) {
      await _auth.sendEmailVerifLink();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Verification email sent. Please verify to log in.")));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Wrapper()));
    }
  }
}
