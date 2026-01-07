import 'package:flutter/material.dart';

/// Paleta de cores minimalista inspirada em ChatGPT, Grok e Gemini AI
class AppColors {
  // Backgrounds - Estilo ChatGPT Dark
  static const Color background = Color(0xFF0D1117); // GitHub dark / ChatGPT
  static const Color surface = Color(0xFF161B22); // Cards
  static const Color surfaceElevated = Color(0xFF1C2128); // Hover states
  static const Color surfaceHover = Color(0xFF21262D); // Interactive hover

  // Text - Hierarquia clara
  static const Color textPrimary = Color(0xFFF0F6FC); // Texto principal
  static const Color textSecondary = Color(0xFF8B949E); // Texto secundário
  static const Color textTertiary = Color(0xFF6E7681); // Texto terciário
  static const Color textDisabled = Color(0xFF484F58); // Texto desabilitado

  // Accents - Cores suaves e modernas
  static const Color primary = Color(0xFF10A37F); // ChatGPT green
  static const Color primaryHover = Color(0xFF0D8B6F);
  static const Color primaryLight = Color(0xFF1A7F64);
  static const Color accent = Color(0xFF3B82F6); // Blue accent
  static const Color accentHover = Color(0xFF2563EB);

  // Borders - Sutis e discretos
  static const Color border = Color(0xFF30363D);
  static const Color borderHover = Color(0xFF484F58);
  static const Color borderFocus = Color(0xFF58A6FF);

  // Status colors - Suaves
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Gradients - Para efeitos sutis
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10A37F), Color(0xFF0D8B6F)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  // Cores específicas para funcionalidades (mantidas para compatibilidade)
  static const Color mintGreen = Color(0xFF34D399);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color red500 = Color(0xFFEF4444);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color purple400 = Color(0xFFA855F7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color indigo600 = Color(0xFF4F46E5);

  // Deprecated - manter para compatibilidade temporária
  @Deprecated('Use AppColors.background instead')
  static const Color deepNavy = background;
  @Deprecated('Use AppColors.surface instead')
  static const Color slateDark = surface;
  @Deprecated('Use AppColors.textSecondary instead')
  static const Color slateLight = textSecondary;
  @Deprecated('Use AppColors.border instead')
  static const Color slate700 = border;
  @Deprecated('Use AppColors.surface instead')
  static const Color slate800 = surface;
  @Deprecated('Use AppColors.background instead')
  static const Color slate900 = background;
}


