import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/env.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Dark status bar for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const BilldoraApp());
}

class BilldoraApp extends StatelessWidget {
  const BilldoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => SupabaseService()),
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
        title: 'Billdora',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.dark, // Force dark mode
        routerConfig: AppRouter.router,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color scaffoldBg = Color(0xFF0A0A0B);
    const Color cardBg = Color(0xFF141417);
    const Color cardBorder = Color(0xFF1F1F23);
    const Color textPrimary = Color(0xFFFFFFFF);
    const Color textSecondary = Color(0xFF71717A);
    const Color accentBlue = Color(0xFF3B82F6);
    const Color accentGreen = Color(0xFF22C55E);
    const Color accentRed = Color(0xFFEF4444);
    const Color accentPurple = Color(0xFF8B5CF6);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.dark(
        surface: scaffoldBg,
        primary: accentBlue,
        secondary: accentPurple,
        error: accentRed,
        onSurface: textPrimary,
        onPrimary: textPrimary,
        surfaceContainerHighest: cardBg,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        height: 70,
        indicatorColor: accentBlue.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) 
                ? FontWeight.w600 
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) 
                ? accentBlue 
                : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) 
                ? accentBlue 
                : textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
    );
  }
}

// Global color constants for easy access
class AppColors {
  static const Color background = Color(0xFF0A0A0B);
  static const Color cardBackground = Color(0xFF141417);
  static const Color cardBorder = Color(0xFF1F1F23);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color blue = Color(0xFF3B82F6);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);
  static const Color cyan = Color(0xFF06B6D4);
}
