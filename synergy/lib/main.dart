import 'package:flutter/material.dart';
import 'package:synergy/views/Admin.view.dart';
import 'package:synergy/views/Appointment.view.dart';
import 'package:synergy/views/Dashboard.view.dart';
import 'package:synergy/views/Ovarian.view.dart';
import 'package:synergy/views/Settings.view.dart';
import 'package:synergy/views/cervical.view.dart';
import 'package:synergy/views/education.view.dart';
import 'package:synergy/views/login.view.dart';
import 'package:synergy/views/profile.view.dart';
import 'package:synergy/views/register.view.dart';

void main() {
  runApp(const HerHealthApp());
}

class HerHealthApp extends StatelessWidget {
  const HerHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerHealth Predict',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/login':
            page = const LoginScreen();
            break;
          case '/register':
            page = const RegisterScreen();
            break;
          case '/dashboard':
            page = const MainScreen(initialIndex: 0);
            break;
          case '/cervical':
            page = const MainScreen(initialIndex: 1);
            break;
          case '/ovarian':
            page = const MainScreen(initialIndex: 2);
            break;
          case '/profile':
            page = const MainScreen(initialIndex: 3);
            break;
          case '/appointments':
            page = const MainScreen(initialIndex: 4);
            break;
          case '/education':
            page = const MainScreen(initialIndex: 5);
            break;
          case '/admin':
            page = const MainScreen(initialIndex: 6);
            break;
          case '/settings':
            page = const MainScreen(initialIndex: 7);
            break;
          default:
            page = const LoginScreen();
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween(
                  begin: 0.0,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, required this.initialIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CervicalScreen(),
    const OvarianScreen(),
    const ProfileScreen(),
    const AppointmentsScreen(),
    const EducationScreen(),
    const AdminScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      final routes = [
        '/dashboard',
        '/cervical',
        '/ovarian',
        '/profile',
        '/appointments',
        '/education',
        '/admin',
        '/settings',
      ];
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      drawer: _buildSidebar(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      width: 200,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'H❤️P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sarah Johnson',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              'Dashboard',
              '/dashboard',
              Icons.home,
              _currentIndex == 0,
            ),
            _buildDrawerItem(
              'Cervical',
              '/cervical',
              Icons.medical_services,
              _currentIndex == 1,
            ),
            _buildDrawerItem(
              'Ovarian',
              '/ovarian',
              Icons.bubble_chart,
              _currentIndex == 2,
            ),
            _buildDrawerItem(
              'Profile',
              '/profile',
              Icons.person,
              _currentIndex == 3,
            ),
            _buildDrawerItem(
              'Appointments',
              '/appointments',
              Icons.calendar_today,
              _currentIndex == 4,
            ),
            _buildDrawerItem(
              'Education',
              '/education',
              Icons.book,
              _currentIndex == 5,
            ),
            _buildDrawerItem(
              'Admin',
              '/admin',
              Icons.analytics,
              _currentIndex == 6,
            ),
            _buildDrawerItem(
              'Settings',
              '/settings',
              Icons.settings,
              _currentIndex == 7,
            ),
            const Spacer(),
            _buildDrawerItem(
              'Logout',
              '/login',
              Icons.logout,
              false,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    String title,
    String route,
    IconData icon,
    bool isActive, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.white.withOpacity(0.2),
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        } else if (!isActive) {
          setState(() {
            _currentIndex = [
              '/dashboard',
              '/cervical',
              '/ovarian',
              '/profile',
              '/appointments',
              '/education',
              '/admin',
              '/settings',
            ].indexOf(route);
          });
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFF666666),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          _buildNavItem(Icons.home, 'Dashboard', _currentIndex == 0),
          _buildNavItem(Icons.medical_services, 'Cervical', _currentIndex == 1),
          _buildNavItem(Icons.bubble_chart, 'Ovarian', _currentIndex == 2),
          _buildNavItem(Icons.person, 'Profile', _currentIndex == 3),
          _buildNavItem(
            Icons.calendar_today,
            'Appointments',
            _currentIndex == 4,
          ),
          _buildNavItem(Icons.book, 'Education', _currentIndex == 5),
          _buildNavItem(Icons.analytics, 'Admin', _currentIndex == 6),
          _buildNavItem(Icons.settings, 'Settings', _currentIndex == 7),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
  ) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        transform:
            isActive ? Matrix4.identity().scaled(1.1) : Matrix4.identity(),
        decoration:
            isActive
                ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFff6b9d), Color(0xFFc44cff)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                )
                : null,
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : const Color(0xFF666666),
        ),
      ),
      label: label,
    );
  }
}
