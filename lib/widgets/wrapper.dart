import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:quran_mobile/auth/verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  Future<void> _checkUserRole(User user) async {
    final adminDoc = await FirebaseFirestore.instance
        .collection('admin')
        .doc(user.uid)
        .get();

    if (adminDoc.exists) {
      Get.offNamed('/admin');
    } else {
      Get.offNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            if (user.emailVerified) {
              Future.microtask(() => _checkUserRole(user));
              return const SizedBox();
            } else {
              return const VerificationScreen();
            }
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
