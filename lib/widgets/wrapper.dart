import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:quran_mobile/auth/verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("Error"),
              );
            } else {
              if (snapshot.data == null) {
                return LoginScreen();
              } else {
                if (snapshot.data?.emailVerified == true) {
                  Future.delayed(Duration.zero, () {
                    Get.offNamed('/home');
                  });
                }
                return VerificationScreen();
              }
            }
          }),
    );
  }
}
