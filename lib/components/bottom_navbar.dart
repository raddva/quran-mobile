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
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.transparent),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: GNav(
                backgroundColor: Colors.transparent,
                color: Colors.green,
                activeColor: Colors.green,
                tabBackgroundColor: Colors.green.withOpacity(0.3),
                gap: 10,
                padding: EdgeInsets.all(16),
                onTabChange: (value) {
                  controller.index.value = value;
                },
                tabs: [
                  GButton(
                    icon: CupertinoIcons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: CupertinoIcons.calendar,
                    text: 'Planner',
                  ),
                  GButton(
                    icon: CupertinoIcons.bookmark,
                    text: 'Bookmark',
                  ),
                  GButton(
                    icon: CupertinoIcons.chart_bar,
                    text: 'Tracker',
                  ),
                  GButton(
                    icon: CupertinoIcons.person,
                    text: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
