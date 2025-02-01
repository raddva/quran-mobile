import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quran_mobile/auth/signin_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quran_mobile/screens/onboarding.dart';

void main() async {
  await dotenv.load(fileName: "assets/.env");
  String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: apiKey,
            authDomain: "alquran-tracker.web.app",
            databaseURL:
                "https://quran-tracker-25-default-rtdb.asia-southeast1.firebasedatabase.app",
            projectId: "quran-tracker-25",
            storageBucket: "quran-tracker-25.firebasestorage.app",
            messagingSenderId: "422889200499",
            appId: "1:422889200499:web:c5e0f4af08651535354306",
            measurementId: "G-1LTRD1JM7H"));
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // home: OnboardingScreen(),
      home: LoginScreen(),
    );
  }
}
