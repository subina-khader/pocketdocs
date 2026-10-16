import 'package:flutter/material.dart';

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const IconBox({
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primaryContainer.withOpacity(.65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}
