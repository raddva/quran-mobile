import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quran_mobile/controllers/bottom_nav_controller.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  BottomNavController controller = Get.put(BottomNavController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => controller.pages[controller.index.value]),
      extendBody: true,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1.5,
                    ),
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GNav(
                    backgroundColor: Colors.transparent,
                    color: Colors.green,
                    activeColor: Colors.green,
                    tabBackgroundColor: Colors.green.withOpacity(0.1),
                    gap: 10,
                    padding: const EdgeInsets.all(16),
                    onTabChange: (value) {
                      controller.index.value = value;
                    },
                    tabs: [
                      GButton(icon: CupertinoIcons.home, text: 'Home'),
                      GButton(icon: CupertinoIcons.calendar, text: 'Planner'),
                      GButton(icon: CupertinoIcons.bookmark, text: 'Bookmark'),
                      GButton(icon: CupertinoIcons.chart_bar, text: 'Tracker'),
                      GButton(icon: CupertinoIcons.person, text: 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
