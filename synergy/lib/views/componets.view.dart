import 'package:flutter/material.dart';

class Logo extends StatefulWidget {
  const Logo({super.key});

  @override
  _LogoState createState() => _LogoState();
}

class _LogoState extends State<Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(102, 126, 234, 0.3),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'H❤️P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String placeholder;
  final TextInputType type;
  final bool obscureText;
  final String? initialValue;

  const InputField({
    super.key,
    required this.placeholder,
    this.type = TextInputType.text,
    this.obscureText = false,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: type,
      obscureText: obscureText,
      controller: initialValue != null ? TextEditingController(text: initialValue) : null,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF666666),
        ),
        filled: true,
        fillColor: const Color.fromRGBO(255, 255, 255, 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        // boxShadow: const [
        //   BoxShadow(
        //     color: Color.fromRGBO(0, 0, 0, 0.1),
        //     blurRadius: 25,
        //     offset: Offset(0, 8),
        //   ),
        // ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFC44CFF),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(255, 107, 157, 0.4),
              blurRadius: 30,
              offset: Offset(0, 10),
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

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SecondaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}