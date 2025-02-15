import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/auth/forgot_password_screen.dart';
import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final auth = AuthService();
  User? user;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      nameController.text = user?.displayName ?? '';
      emailController.text = user?.email ?? '';
    }
  }

  void updateUserInfo() async {
    String newName = nameController.text;
    String newEmail = emailController.text;

    bool success = await auth.updateUserInfo(newName, newEmail);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User information updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user information.')),
      );
    }
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
                Icon(
                  CupertinoIcons.profile_circled,
                  color: Colors.green,
                  size: 250,
                ),
                SizedBox(height: 40),
                CustomTextField(
                  controller: nameController,
                  hint: "Display Name",
                  isDisabled: true,
                  label: "Name",
                  icon: CupertinoIcons.person,
                ),
                SizedBox(height: 20),
                CustomTextField(
                  controller: emailController,
                  hint: "Email",
                  isDisabled: true,
                  label: "Email",
                  icon: CupertinoIcons.mail,
                ),
                SizedBox(height: 20),
                // CustomButton(
                //   label: "Save Changes",
                //   onPressed: updateUserInfo,
                // ),
                SizedBox(height: 50),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ));
                  },
                  child: Text(
                    "Change Password",
                    style: TextStyle(
                      color: Colors.green[600],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                CustomButton(
                  label: "Sign Out",
                  onPressed: () async {
                    await auth.signOut();
                    goToLogin(context);
                  },
                )
              ],
            ),
          ),
        ));
  }
}

goToLogin(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
