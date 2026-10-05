import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

/// 模擬網頁版 text-shadow / box-shadow 疊層發光效果的工具。
class AppGlow {
  AppGlow._();

  /// 回傳一組多層 [BoxShadow]，以遞增的 blurRadius（8 / 16 / 32）疊加出光暈。
  ///
  /// [intensity] 控制發光強度分級：1.0 為一般發光，1.5 為強發光
  /// （例如按鈕按下或動爻標示時使用）。
  static List<BoxShadow> shadow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.55 * intensity),
        blurRadius: 8 * intensity,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.35 * intensity),
        blurRadius: 16 * intensity,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.2 * intensity),
        blurRadius: 32 * intensity,
      ),
    ];
  }
}

/// App 的整體 ThemeData 設定。
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGlow,
      brightness: Brightness.dark,
      primary: AppColors.primaryGlow,
      surface: AppColors.backgroundDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: AppTextTheme.guaFontFamily,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.primaryGlow,
          side: const BorderSide(color: AppColors.primaryGlow, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundDarker,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryGlow, width: 1),
        ),
      ),
    );
  }
}
