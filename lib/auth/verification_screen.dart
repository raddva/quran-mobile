import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:quran_mobile/widgets/button.dart';
import 'package:quran_mobile/widgets/wrapper.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _auth = AuthService();
  late Timer timer;
  @override
  void initState() {
    super.initState();
    _auth.sendEmailVerifLink();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      FirebaseAuth.instance.currentUser?.reload();
      if (FirebaseAuth.instance.currentUser!.emailVerified == true) {
        timer.cancel();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Wrapper()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "We have sent an email for verification. Please check your inbox.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: "Resend Email",
                onPressed: () async {
                  _auth.sendEmailVerifLink();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
