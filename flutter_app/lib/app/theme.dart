import 'package:flutter/material.dart';

/// Tailwind zinc/indigo palette used by the original Next.js frontend.
class AppColors {
  static const zinc950 = Color(0xFF09090B);
  static const zinc900 = Color(0xFF18181B);
  static const zinc800 = Color(0xFF27272A);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc600 = Color(0xFF52525B);
  static const zinc500 = Color(0xFF71717A);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc200 = Color(0xFFE4E4E7);

  static const white = Color(0xFFFFFFFF);

  static const indigo600 = Color(0xFF4F46E5);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo400 = Color(0xFF818CF8);

  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const amber500 = Color(0xFFF59E0B);
  static const amber400 = Color(0xFFFBBF24);
  static const red500 = Color(0xFFEF4444);
  static const red400 = Color(0xFFF87171);
  static const blue400 = Color(0xFF60A5FA);
  static const blue600 = Color(0xFF2563EB);
  static const rose600 = Color(0xFFE11D48);
  static const rose400 = Color(0xFFFB7185);
  static const green600 = Color(0xFF16A34A);
  static const slate600 = Color(0xFF475569);
  static const violet600 = Color(0xFF7C3AED);
  static const orange600 = Color(0xFFEA580C);
  static const purple400 = Color(0xFFC084FC);

  // Avatar color per agent id (AgentBubble AGENT_COLORS).
  static const Map<String, Color> agentColors = {
    'moderator': blue600,
    'synthesizer': rose600,
    'skeptical_investor': red500,
    'early_adopter': green600,
    'enterprise_cto': slate600,
    'ux_researcher': violet600,
    'growth_marketer': orange600,
  };
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.zinc950,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.zinc950,
      primary: AppColors.indigo600,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
  );
}
