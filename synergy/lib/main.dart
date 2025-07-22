import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synergy/firebase_options.dart';
import 'package:synergy/views/Admin.view.dart';
import 'package:synergy/views/Appointment.view.dart';
import 'package:synergy/views/Dashboard.view.dart';
import 'package:synergy/views/Ovarian.view.dart';
import 'package:synergy/views/Ovarian_results.views.dart';
import 'package:synergy/views/Settings.view.dart';
import 'package:synergy/views/all_data_screen.dart';
import 'package:synergy/views/cervical.view.dart';
import 'package:synergy/views/cervical_results.views.dart';
import 'package:synergy/views/doctor_dashboard.views.dart';
import 'package:synergy/views/education.view.dart';
import 'package:synergy/views/login.view.dart';
import 'package:synergy/views/profile.view.dart';
import 'package:synergy/views/register.view.dart';

void main() async {
  if (!kIsWeb) {
    // Platform-specific WebView initialization would go here
    // But since webview_flutter doesn't work on web anyway,
    // we skip this initialization
  }

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const HerHealthApp());
}

class HerHealthApp extends StatefulWidget {
  const HerHealthApp({super.key});

  @override
  State<HerHealthApp> createState() => _HerHealthAppState();
}

class _HerHealthAppState extends State<HerHealthApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveTheme(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HerHealth Predict',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.pink,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF667eea),
          unselectedItemColor: Color(0xFF999999),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      ),
      darkTheme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.pink,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[850],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF333333),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[850],
          selectedItemColor: const Color(0xFF667eea),
          unselectedItemColor: const Color(0xFF999999),
        ),
        drawerTheme: DrawerThemeData(backgroundColor: Colors.grey[900]),
      ),
      themeMode: _themeMode,
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
          case '/appointments':
            page = const MainScreen(initialIndex: 3);
            break;
          case '/profile':
            page = const MainScreen(initialIndex: 4);
            break;
          case '/settings':
            page = const MainScreen(initialIndex: 5);
            break;
          case '/education':
            page = const MainScreen(initialIndex: 6);
            break;
          case '/admin':
            page = const MainScreen(initialIndex: 7);
            break;
          case '/health-data':
            page = HealthDataScreen();
            break;
          case '/doctor':
            page = const MainScreen(initialIndex: 8);
            break;
          case '/cervical_results':
            final args = settings.arguments as Map<String, dynamic>?;
            final patientId = args?['patientId'] ?? '';
            page = DoctorCervicalResultsScreen(patientId: patientId);
            break;
          case '/ovarian_results':
            final args = settings.arguments as Map<String, dynamic>?;
            final patientId = args?['patientId'] ?? '';
            final patientName = args?['patientName'] ?? '';
            page = DoctorOvarianResultsScreen(
              patientId: patientId,
              patientName: patientName,
            );
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
    const AppointmentsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    const DoctorDashboardScreens(),
    const InventoryScreen(region: ''),
    const DoctorDashboardScreen(),
  ];

  final List<String> _bottomNavRoutes = [
    '/dashboard',
    '/cervical',
    '/ovarian',
    '/appointments',
    '/profile',
    '/settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  void _onNavItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      Navigator.pushReplacementNamed(context, _bottomNavRoutes[index]);
    }
  }

  Future<String> _getCurrentPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('patient_id');
    if (patientId == null || patientId.isEmpty) {
      patientId = 'demo_patient_123';
    }
    return patientId;
  }

  void _navigateToRoute(String route) async {
    Navigator.pop(context); // Close drawer

    // Special handling for cervical results
    if (route == '/cervical_results') {
      String patientId = await _getCurrentPatientId();
      Navigator.pushNamed(
        context,
        '/cervical_results',
        arguments: {'patientId': patientId},
      );
      return;
    }

    // Special handling for ovarian results
    if (route == '/ovarian_results') {
      String patientId = await _getCurrentPatientId();
      Navigator.pushNamed(
        context,
        '/ovarian_results',
        arguments: {'patientId': patientId, 'patientName': 'Unknown'},
      );
      return;
    }

    final routeIndex = _getRouteIndex(route);
    if (routeIndex != -1 && routeIndex != _currentIndex) {
      setState(() {
        _currentIndex = routeIndex;
      });
      Navigator.pushReplacementNamed(context, route);
    } else if (route == '/login') {
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid route selected')));
    }
  }

  int _getRouteIndex(String route) {
    final allRoutes = [
      '/dashboard',
      '/cervical',
      '/ovarian',
      '/appointments',
      '/profile',
      '/settings',
      '/education',
      '/admin',
      '/doctor',
    ];
    return allRoutes.indexOf(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _screens[_currentIndex],
      drawer: _buildSidebar(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF667eea),
                  size: 24,
                ),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_rounded,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF667eea),
                size: 24,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        'H❤️P',
                        style: TextStyle(
                          color: Color(0xFF667eea),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sarah Johnson',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Patient ID: #12345',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30, thickness: 1),
              _buildDrawerSection('MAIN', [
                _buildDrawerItem('Dashboard', '/dashboard', Icons.home),
              ]),
              _buildDrawerSection('TOOLS & RESOURCES', [
                _buildDrawerItem('Education', '/education', Icons.book),
                _buildDrawerItem('Admin Panel', '/admin', Icons.analytics),
              ]),
              const Spacer(),
              _buildDrawerSection('ACCOUNT', [
                _buildDrawerItem(
                  'Logout',
                  '/login',
                  Icons.logout,
                  isLogout: true,
                ),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem(
    String title,
    String route,
    IconData icon, {
    bool isLogout = false,
  }) {
    final isActive = _getRouteIndex(route) == _currentIndex && !isLogout;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isActive
                ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2)
                : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isActive
                  ? Theme.of(context).textTheme.bodyMedium!.color
                  : Theme.of(
                    context,
                  ).textTheme.bodyMedium!.color!.withOpacity(0.7),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                isActive
                    ? Theme.of(context).textTheme.bodyMedium!.color
                    : Theme.of(
                      context,
                    ).textTheme.bodyMedium!.color!.withOpacity(0.7),
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _navigateToRoute(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    if (_currentIndex >= 6) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _currentIndex.clamp(0, 5),
          onTap: _onNavItemTapped,
          backgroundColor:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor:
              Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            _buildNavItem(Icons.home_rounded, 'Home', _currentIndex == 0),
            _buildNavItem(
              Icons.medical_services_rounded,
              'Cervical',
              _currentIndex == 1,
            ),
            _buildNavItem(
              Icons.bubble_chart_rounded,
              'Ovarian',
              _currentIndex == 2,
            ),
            _buildNavItem(
              Icons.calendar_today_rounded,
              'Appointments',
              _currentIndex == 3,
            ),
            _buildNavItem(Icons.person_rounded, 'Profile', _currentIndex == 4),
            _buildNavItem(
              Icons.settings_rounded,
              'Settings',
              _currentIndex == 5,
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(8),
        decoration:
            isActive
                ? BoxDecoration(
                  color: Theme.of(context)
                      .bottomNavigationBarTheme
                      .selectedItemColor!
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                )
                : null,
        child: Icon(icon, size: 24),
      ),
      label: label,
    );
  }
}
