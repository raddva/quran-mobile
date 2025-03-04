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
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Obx(() => controller.pages[controller.index.value]),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 20,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: screenWidth * 0.9,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
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
                      gap: 2,
                      padding: EdgeInsets.all(6),
                      onTabChange: (value) {
                        controller.index.value = value;
                      },
                      tabs: [
                        GButton(
                            icon: CupertinoIcons.home,
                            text: 'Home',
                            iconSize: 22),
                        GButton(
                            icon: CupertinoIcons.calendar,
                            text: 'Planner',
                            iconSize: 22),
                        GButton(
                            icon: CupertinoIcons.bookmark,
                            text: 'Bookmark',
                            iconSize: 22),
                        GButton(
                            icon: CupertinoIcons.chart_bar,
                            text: 'Tracker',
                            iconSize: 22),
                        GButton(
                            icon: CupertinoIcons.person,
                            text: 'Profile',
                            iconSize: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
