import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.style});

  static const sunColor = Color(0xFFFFC94D);

  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Mudar para tema claro' : 'Mudar para tema escuro',
      onPressed: () => AppSettings.instance.setThemeMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      ),
      style: style,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: .5, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: isDark ? sunColor : null,
        ),
      ),
    );
  }
}
