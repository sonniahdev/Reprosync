import 'package:flutter/material.dart';

class CervicalScreen extends StatelessWidget {
  const CervicalScreen({super.key});

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
                    _buildHeader(context),
                    _buildContent(),
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '21:19', // Updated to current time (09:19 PM EAT)
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
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
                  'Cervical Health',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comprehensive risk assessment & tracking',
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
          Positioned(
            top: 60,
            left: 20,
            child: _buildBackButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
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
            child: const Center(
              child: Column(
                children: [
                  Text(
                    'LOW RISK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '12%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Based on your recent HPV screening, age, and health history',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Risk Factors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard('✅ HPV Vaccination', 'Completed - Gardasil 9 series'),
          _buildRecommendationCard('✅ Recent Screening', 'Normal Pap smear - March 2025'),
          _buildRecommendationCard('⚠️ Family History', 'Mother diagnosed at age 45 - increases monitoring importance'),
          const SizedBox(height: 20),
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard('📅 Next Screening', 'February 2026 - We\'ll remind you 2 months prior'),
          _buildRecommendationCard('🏃‍♀️ Lifestyle', 'Continue current exercise routine and maintain healthy diet'),
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
          child: Text(
            '←',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity, // Ensure full width
      height: 100, // Fixed height for uniformity
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.split(' ').first, // Extract the emoji
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.split(' ').sublist(1).join(' '), // Remove emoji from title
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                    fontFamily: 'SF Pro Display',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}