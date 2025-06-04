import 'package:flutter/material.dart';

class OvarianScreen extends StatelessWidget {
  const OvarianScreen({super.key});

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
            '21:24', // Updated to current time (09:24 PM EAT)
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
                  'Ovarian Health',
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
                  'AI-powered cyst monitoring & analysis',
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
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
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
                    'MONITORING',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '2',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Small cysts detected - actively monitoring growth patterns',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Current Cysts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard(
            '🫧 Left Ovary - Functional Cyst',
            '2.3cm diameter • Decreasing size • Expected to resolve naturally',
          ),
          _buildRecommendationCard(
            '🫧 Right Ovary - Follicular Cyst',
            '1.8cm diameter • Stable size • Typical appearance',
          ),
          const SizedBox(height: 20),
          const Text(
            'Growth Predictions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          _buildRecommendationCard(
            '📈 AI Analysis',
            '85% probability both cysts will resolve within 3 months without intervention',
          ),
          _buildRecommendationCard(
            '🔍 Next Ultrasound',
            'Recommended in 6 weeks to track progression',
          ),
          _buildRecommendationCard(
            '⚠️ Watch Symptoms',
            'Contact us if you experience severe pelvic pain or unusual bleeding',
          ),
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

  Widget _buildRecommendationCard(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity, // Match previous card width
      height: 100, // Match previous card height
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
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title
                      .split(' ')
                      .sublist(1)
                      .join(' '), // Remove emoji from title
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
