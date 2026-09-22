import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PocketDocsLogo extends StatelessWidget {
  const PocketDocsLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .32),
        gradient: const LinearGradient(
          colors: [AppTheme.brand, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withOpacity(.25),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        Icons.description_outlined,
        color: Colors.white,
        size: size * .52,
      ),
    );
  }
}
