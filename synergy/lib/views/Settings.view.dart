import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '21:43', // Updated to current time (09:43 PM EAT)
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings',
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
                  'Customize your HerHealth experience',
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
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
          _buildSettingsGroup(
            'Account',
            [
              _buildSettingsItem('Email', 'sarah@example.com'),
              _buildSettingsItem('Role', 'Patient'),
            ],
            buttonText: 'Update Account',
            onButtonPressed: () {},
          ),
          _buildSettingsGroup(
            'Preferences',
            [
              _buildSettingsItem('Notifications', 'On', isToggle: true),
              _buildSettingsItem('Language', 'English'),
              _buildSettingsItem('Theme', 'Light'),
            ],
            buttonText: 'Save Changes',
            onButtonPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    String title,
    List<Widget> items, {
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 4,
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
            ),
          ),
          const SizedBox(height: 15),
          ...items,
          if (buttonText != null) ...[
            const SizedBox(height: 15),
            _buildButton(buttonText, onButtonPressed!),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String label,
    String value, {
    bool isToggle = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          isToggle
              ? Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFff6b9d),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 30,
        ), // Increased padding for larger size
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: const Color(0xFFff6b9d).withOpacity(0.4),
        minimumSize: const Size(
          double.infinity,
          60,
        ), // Increased minimum height to 60
      ).copyWith(
        backgroundColor: MaterialStateProperty.all(
          const Color.fromARGB(0, 0, 0, 0),
        ),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff6b9d), Color(0xFFc44cff)],
          ),
          borderRadius: BorderRadius.circular(16),
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
