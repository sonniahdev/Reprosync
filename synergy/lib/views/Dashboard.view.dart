import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFffeef8), Color(0xFFf8f0ff), Color(0xFFe8f5ff)],
          ),
        ),
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildContent(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '9:41',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
            ),
            Text(
              '🔋 100%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, // Ensure the header covers the full width
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good morning, Sarah! 🌸',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tuesday, June 4, 2025', // Updated to current date
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [Color(0xFF4CAF50), Color(0x33FFFFFF)],
                        stops: [0.85, 0.85],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text(
                            '85',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Overall Health Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'SF Pro Display',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Looking great this month!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontFamily: 'SF Pro Display',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Health Modules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHealthCard('Cervical Health', '🔬', 'Low Risk', () => Navigator.pushNamed(context, '/cervical')),
              _buildHealthCard('Ovarian Cysts', '🫧', '2 Monitored', () => Navigator.pushNamed(context, '/ovarian')),
              _buildHealthCard('My Profile', '👤', 'Updated', () => Navigator.pushNamed(context, '/profile')),
              _buildHealthCard('Appointments', '📅', 'Next: Jun 15', () => Navigator.pushNamed(context, '/appointments')),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Recent Updates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard('🎉 Great news!', 'Your recent screening results came back normal. Keep up the great work with your preventive care!'),
          _buildRecommendationCard('📱 Reminder', 'Your next cervical screening is due in 8 months. We\'ll send you a reminder closer to the date.'),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String icon, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(
                fontSize: 40,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              fontFamily: 'SF Pro Display',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
              fontFamily: 'SF Pro Display',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}