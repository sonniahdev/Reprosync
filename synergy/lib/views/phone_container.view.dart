import 'package:flutter/material.dart';

class PhoneContainer extends StatelessWidget {
  const PhoneContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375,
      height: 812,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFEEF8), Color(0xFFF8F0FF), Color(0xFFE8F5FF)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
