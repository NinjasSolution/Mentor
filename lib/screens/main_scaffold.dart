import 'package:bgnu_mentor/screens/community/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:bgnu_mentor/screens/home/home_screen.dart';
import 'package:bgnu_mentor/screens/messages/messages_screen.dart';
import 'package:bgnu_mentor/screens/profile/profile_screen.dart';
import 'package:bgnu_mentor/screens/users/users_screen.dart';
import 'package:bgnu_mentor/screens/mentor/mentor_dashboard.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MentorDashboard(),
    const CommunityScreen(),
    const UsersScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
