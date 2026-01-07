import 'package:flutter/material.dart';

/// Paleta de cores minimalista inspirada em ChatGPT, Grok e Gemini AI
class AppColors {
  // Backgrounds - Estilo ChatGPT Dark
  static const Color background = Color(0xFFF5F7FA); // Light minimalist background
  static const Color surface = Color(0xFFFFFFFF); // Pure white surface
  static const Color surfaceSoft = Color(0xFFF0F4F8); // Very light grey blue
  static const Color surfaceGlass = Color(0xCCFFFFFF); // Glass effect white
  static const Color surfaceHover = Color(0xFFF8FAFC);

  // Text - Hierarquia clara
  static const Color textPrimary = Color(0xFF1F2937); // Dark grey text
  static const Color textSecondary = Color(0xFF6B7280); // Medium grey
  static const Color textTertiary = Color(0xFF9CA3AF); // Light grey
  static const Color textDisabled = Color(0xFFD1D5DB);

  // Accents - Cores suaves e modernas
  // Accents - Modern & Fresh
  static const Color primary = Color(0xFF2563EB); // Vibrant Blue
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE); // Very light blue for backgrounds
  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color accentHover = Color(0xFF059669);

  // Borders - Sutis e discretos
  // Borders - Very Subtle
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderHover = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFFBFDBFE);
  
  // Shadows - Soft & Diffused
  static const Color shadowSoft = Color(0x1A000000); // 10% Black
  static const Color shadowStrong = Color(0x33000000); // 20% Black

  // Status colors - Suaves
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Gradients - Para efeitos sutis
  // Gradients - Soft & Modern
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
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


