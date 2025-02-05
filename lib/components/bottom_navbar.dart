import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Import for BackdropFilter
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 10),
                    child: GNav(
                      backgroundColor: Colors.transparent,
                      color: Colors.black,
                      activeColor: Colors.black,
                      tabBackgroundColor: Colors.black.withOpacity(0.3),
                      gap: 10,
                      padding: EdgeInsets.all(16),
                      onTabChange: (value) {},
                      tabs: [
                        GButton(
                          icon: CupertinoIcons.home,
                          text: 'Home',
                        ),
                        GButton(
                          icon: CupertinoIcons.heart,
                          text: 'Likes',
                        ),
                        GButton(
                          icon: CupertinoIcons.search,
                          text: 'Search',
                        ),
                        GButton(
                          icon: CupertinoIcons.settings,
                          text: 'Settings',
                        ),
                      ],
                    ),
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
