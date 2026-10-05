import 'package:flutter/material.dart';

/// App 的核心配色 tokens，對應網頁版的青綠霓虹視覺風格。
class AppColors {
  AppColors._();

  /// 青綠霓虹主色，用於發光效果、按鈕與卡片邊框。
  static const Color primaryGlow = Color(0xFF39FFE2);

  /// 深色背景。
  static const Color backgroundDark = Color(0xFF0A1B18);

  /// 更深的漸層底色，搭配 [backgroundDark] 做背景漸層。
  static const Color backgroundDarker = Color(0xFF051010);

  static const Color textPrimary = Color(0xFFE8FFFB);
  static const Color textSecondary = Color(0xFF7FBFB5);

  /// 金黃色，用於占卜結果相關的強調視覺（例如卦辭判斷、太極指標）。
  static const Color resultGold = Color(0xFFFFD700);
}
