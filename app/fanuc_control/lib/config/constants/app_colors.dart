import 'package:flutter/material.dart';

/// App color constants matching the dark theme design
class AppColors {
  // Background colors
  static const Color background = Color(0xFF09090B); // zinc-950
  static const Color backgroundSecondary = Color(0xFF18181B); // zinc-900
  static const Color cardBackground = Color(0xFF18181B); // zinc-900/50 with opacity
  static const Color surface = Color(0xFF27272A); // zinc-800

  // Primary accent colors (yellow/orange gradient)
  static const Color primaryYellow = Color(0xFFEAB308); // yellow-500
  static const Color primaryOrange = Color(0xFFEA580C); // orange-600
  static const Color primaryYellowLight = Color(0xFFFCD34D); // yellow-400
  static const Color primaryOrangeLight = Color(0xFFF97316); // orange-500

  // Text colors
  static const Color textPrimary = Color(0xFFFAFAFA); // zinc-50 (white)
  static const Color textSecondary = Color(0xFFA1A1AA); // zinc-400
  static const Color textTertiary = Color(0xFF71717A); // zinc-500

  // Status colors
  static const Color success = Color(0xFF22C55E); // green-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color info = Color(0xFF3B82F6); // blue-500

  // Border colors
  static const Color border = Color(0xFF3F3F46); // zinc-700
  static const Color borderLight = Color(0xFF52525B); // zinc-600

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color yellowOverlay = Color(0x1AEAB308); // yellow-500/10

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEAB308), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientHover = LinearGradient(
    colors: [Color(0xFFFCD34D), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

