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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
                            TImages.signUpImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                        VerticalDivider(thickness: 1, color: Colors.green[700]),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: _buildSignupForm(),
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
                        TImages.signUpImage,
                        width: THelperFunctions.screenWidth() * 0.5,
                        height: THelperFunctions.screenHeight() * 0.4,
                      ),
                      _buildSignupForm(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          SizedBox(height: 10),
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
