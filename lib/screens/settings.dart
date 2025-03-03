import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/auth/forgot_password_screen.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quran_mobile/widgets/alert_dialog.dart';

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
    showCustomAlertDialog(
      context,
      "Confirm Deletion",
      "Are you sure you want to delete this note?",
      onConfirm: () async {
        String newName = nameController.text;
        String newEmail = emailController.text;

        bool success = await auth.updateUserInfo(newName, newEmail);

        if (success) {
          showSuccessAlert(context, "User information updated successfully.");
        } else {
          showCustomAlertDialog(
              context, "Failed", "Failed to update user information.");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 50,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: Text(
              "Profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(CupertinoIcons.square_arrow_left, color: Colors.red),
                onPressed: () async {
                  await auth.signOut();
                  Get.offNamed('/auth');
                },
                tooltip: "Sign Out",
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              Center(
                child: Icon(
                  CupertinoIcons.profile_circled,
                  color: Colors.green,
                  size: 150,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: nameController,
                      hint: "Display Name",
                      // isDisabled: true,
                      label: "Name",
                      icon: CupertinoIcons.person,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: emailController,
                      hint: "Email",
                      // isDisabled: true,
                      label: "Email",
                      icon: CupertinoIcons.mail,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Get.to(() => const ForgotPasswordScreen());
                      },
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: "Save Changes",
                      onPressed: updateUserInfo,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
