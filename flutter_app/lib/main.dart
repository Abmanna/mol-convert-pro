import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MolConvertProApp()));
}

class MolConvertProApp extends StatelessWidget {
  const MolConvertProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MolConvert Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.highContrastTheme, // Using high contrast as dark mode for now
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
