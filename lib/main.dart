import 'package:flutter/material.dart';
import 'chat/chat_screen.dart';

void main() {
  runApp(const CampusAgentApp());
}

class CampusAgentApp extends StatelessWidget {
  const CampusAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中南民族大学 校园AI助手',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const ChatScreen(),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF1565C0); // Deep blue — university color

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }
}
