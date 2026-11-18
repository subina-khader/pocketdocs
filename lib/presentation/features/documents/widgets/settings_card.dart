import 'package:flutter/material.dart';



class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}