import 'package:flutter/material.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

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
                  children: [_buildHeader(context), _buildContent()],
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '21:37', // Updated to current time (09:37 PM EAT)
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            '🔋 100%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure full width coverage
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Education & Support',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn and connect for better health',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(top: 60, left: 20, child: _buildBackButton(context)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Educational Resources',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildEducationCard(
            '📚',
            'Understanding Cervical',
            'Learn about risk factors, screening methods, and prevention strategies for cervical health.',
          ),
          _buildEducationCard(
            '📖',
            'Ovarian Cyst Management',
            'Understand types of ovarian cysts, monitoring techniques, and when to seek treatment.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Community Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildEducationCard(
            '🤝',
            'Join Our Support Group',
            'Connect with others for shared experiences and emotional support.',
          ),
          _buildEducationCard(
            '📞',
            'Care Navigation',
            'Get personalized assistance with healthcare resources and appointments.',
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton('Explore More', () {}),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/dashboard'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEducationCard(String icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => Transform.scale(scale: 0.98),
      onTapUp: (_) => onPressed(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff6b9d), Color(0xFFc44cff)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFff6b9d).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
