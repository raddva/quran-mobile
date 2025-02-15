import 'package:dots_indicator/dots_indicator.dart';
import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:quran_mobile/auth/verification_screen.dart';
import 'package:quran_mobile/components/bottom_navbar.dart';
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
              return Center(
                child: DotsIndicator(
                  dotsCount: 3,
                  position: 1,
                  decorator: DotsDecorator(
                    activeColor: Colors.blue,
                    size: Size(10.0, 10.0),
                    activeSize: Size(14.0, 14.0),
                  ),
                ),
              );
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
                  return BottomNavbar();
                }
                return VerificationScreen();
              }
            }
          }),
    );
  }
}
