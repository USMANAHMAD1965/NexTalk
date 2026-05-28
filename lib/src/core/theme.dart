part of '../../main.dart';

class AppColors {
  static const primary = Color(0xFF6D57E8);
  static const primaryDark = Color(0xFF4C36C8);
  static const accent = Color(0xFF12C8A8);
  static const danger = Color(0xFFFF6B5F);
  static const warning = Color(0xFFFFB454);
  static const ink = Color(0xFF161A2D);
  static const muted = Color(0xFF7D8396);
  static const line = Color(0xFFE9EBF3);
  static const surface = Color(0xFFF7F8FC);
  static const softPurple = Color(0xFFF0EDFF);
}

class ZegoSettings {
  // For production, prefer token-based auth from a trusted server.
  static const int appId = 1723908006;
  static const String appSign =
      '021e38e4e579bda0bb60b0f04be7d833b001682c5f13f57cac4a36a746e86c47';

  static bool get isConfigured => appId != 0 && appSign.isNotEmpty;
}

Color tint(Color color, double alpha) => color.withValues(alpha: alpha);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
    ),
  );
}
