import 'package:flutter/material.dart';

class GradientWrapper extends StatelessWidget {
  final Widget child;
  const GradientWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.096, 0.03),
          radius: 1.2,
          colors: [Color(0xFFA8E5FD), Color.fromARGB(255, 255, 254, 250), Color.fromARGB(255, 252, 252, 255)],
          stops: [0.0, 0.423, 1.002],
        ),
      ),
      child: child,
    );
  }
}