import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_mobile/admin/home_admin.dart';
import 'package:quran_mobile/admin/quotes_screen.dart';
import 'package:quran_mobile/admin/users_screen.dart';
import 'package:quran_mobile/auth/auth_service.dart';
import 'package:get/get.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboard(),
    UsersPage(),
    QuotesPage(),
  ];

  void _onSidebarTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            onTap: _onSidebarTap,
            selectedIndex: _selectedIndex,
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final auth = AuthService();

  final Function(int) onTap;
  final int selectedIndex;

  _Sidebar({required this.onTap, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.green[800],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Column(
            children: [
              Image.asset(
                'assets/Images/7.png',
                height: 90,
              ),
              const SizedBox(height: 8),
              const Text(
                'Quran Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _SidebarItem(
            label: 'Dashboard',
            icon: CupertinoIcons.rectangle_3_offgrid_fill,
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          // _SidebarItem(
          //   label: 'Users',
          //   icon: CupertinoIcons.group_solid,
          //   selected: selectedIndex == 1,
          //   onTap: () => onTap(1),
          // ),
          _SidebarItem(
            label: 'Quotes',
            icon: CupertinoIcons.quote_bubble_fill,
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          SizedBox(height: 60),
          _SidebarItem(
            label: 'Logout',
            icon: CupertinoIcons.square_arrow_left,
            selected: selectedIndex == 3,
            onTap: () async {
              await auth.signOut();
              Get.offNamed('/auth');
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      selected: selected,
      selectedTileColor: Colors.green[700],
      onTap: onTap,
    );
  }
}
