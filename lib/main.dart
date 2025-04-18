import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:quran_mobile/admin/admin_layout.dart';
import 'package:quran_mobile/components/bottom_navbar.dart';
import 'package:quran_mobile/screens/onboarding.dart';
import 'package:quran_mobile/widgets/wrapper.dart';
import 'package:timezone/data/latest.dart' as tz;

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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quran Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        // User
        GetPage(name: '/', page: () => OnboardingScreen()),
        GetPage(name: '/home', page: () => BottomNavbar()),
        GetPage(name: '/auth', page: () => Wrapper()),

        // Admin
        GetPage(name: '/admin', page: () => AdminLayout()),
      ],
    );
  }
}
