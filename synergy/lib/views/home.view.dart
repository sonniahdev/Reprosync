import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const Center(
        child: Text(
          'Home Screen (Navigation Placeholder)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.95),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Text('🏠', style: TextStyle(fontSize: 20)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Text('🔬', style: TextStyle(fontSize: 20)),
              label: 'Cervical',
            ),
            BottomNavigationBarItem(
              icon: Text('🫧', style: TextStyle(fontSize: 20)),
              label: 'Ovarian',
            ),
            BottomNavigationBarItem(
              icon: Text('👤', style: TextStyle(fontSize: 20)),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Text('📅', style: TextStyle(fontSize: 20)),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Text('📚', style: TextStyle(fontSize: 20)),
              label: 'Education',
            ),
            BottomNavigationBarItem(
              icon: Text('📊', style: TextStyle(fontSize: 20)),
              label: 'Admin',
            ),
            BottomNavigationBarItem(
              icon: Text('⚙️', style: TextStyle(fontSize: 20)),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF666666),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          onTap: _onItemTapped,
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
          ),
          unselectedIconTheme: const IconThemeData(
            color: Color(0xFF666666),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}