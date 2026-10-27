import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const WorldOfItApp());
}

class WorldOfItApp extends StatelessWidget {
  const WorldOfItApp({super.key});

  static ThemeData _buildLightTheme() {
    const seed = Color(0xFF6B5CA5);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF5D5094),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFECE8F8),
      onPrimaryContainer: const Color(0xFF342C54),
      secondary: const Color(0xFF3D7A60),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE3F4EC),
      onSecondaryContainer: const Color(0xFF214A38),
      tertiary: const Color(0xFF8C6A43),
      tertiaryContainer: const Color(0xFFFBF0E2),
      surface: Colors.white,
      onSurface: const Color(0xFF282438),
      onSurfaceVariant: const Color(0xFF6E6982),
      outline: const Color(0xFF9E99B0),
      outlineVariant: const Color(0xFFE8E4F2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFFF8F7FC),
        foregroundColor: Color(0xFF282438),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8E4F2), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEFECF6),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF5D5094),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: const Color(0xFFECE8F8),
        foregroundColor: const Color(0xFF342C54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDAD3F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAF9FD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B6DB5), width: 1.4),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    const seed = Color(0xFFB8AEE6);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFFC4BBEA),
      onPrimary: const Color(0xFF282142),
      primaryContainer: const Color(0xFF322C4D),
      onPrimaryContainer: const Color(0xFFEAE6FA),
      secondary: const Color(0xFFA6E1C8),
      secondaryContainer: const Color(0xFF243B32),
      onSecondaryContainer: const Color(0xFFD9F3E7),
      surface: const Color(0xFF201E29),
      onSurface: const Color(0xFFECEAF4),
      onSurfaceVariant: const Color(0xFFA39EB8),
      outlineVariant: const Color(0xFF312E3F),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF17161E),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF17161E),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF201E29),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF312E3F), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C293A),
        thickness: 1,
        space: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Sync',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: ApiService().isAuthenticated
          ? const DashboardScreen()
          : const AuthScreen(),
    );
  }
}
