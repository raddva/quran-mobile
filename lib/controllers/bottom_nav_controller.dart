import 'package:get/get.dart';
import 'package:quran_mobile/screens/bookmark.dart';
import 'package:quran_mobile/screens/home.dart';
import 'package:quran_mobile/screens/planner.dart';
import 'package:quran_mobile/screens/settings.dart';
import 'package:quran_mobile/screens/tracker.dart';

class BottomNavController {
  RxInt index = 0.obs;

  var pages = [
    HomeScreen(),
    PlannerScreen(),
    BookmarkScreen(),
    TrackerScreen(),
    SettingsScreen(),
  ];
}
