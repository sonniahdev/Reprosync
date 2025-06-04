import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef), Color(0xFFfecfef)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 30),
                      const Text(
                        'Join HerHealth',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Create your account to start your health journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildInputField('Full Name'),
                      const SizedBox(height: 20),
                      _buildInputField('Email address'),
                      const SizedBox(height: 20),
                      _buildInputField('Date of Birth', isDate: true),
                      const SizedBox(height: 20),
                      _buildInputField('Password', isPassword: true),
                      const SizedBox(height: 15),
                      _buildPrimaryButton('Create Account', () => Navigator.pushNamed(context, '/dashboard')),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: _buildBackButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _animation.value),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'H❤️P',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String hint, {bool isPassword = false, bool isDate = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            spreadRadius: 8,
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
        ),
        keyboardType: isDate ? TextInputType.datetime : null,
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/login'),
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
}