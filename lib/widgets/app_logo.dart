import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.2),
    child: Image.asset(
      'assets/branding/logo.jpeg',
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: 'شعار كبّاس',
    ),
  );
}
