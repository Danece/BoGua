import 'package:flutter/material.dart';

/// 集中管理 App 的文字樣式。
///
/// 卦名、卦辭爻辭等易經內文使用開源楷體 [guaFontFamily]（cwTeXKai，
/// SIL Open Font License 1.1），介面用的按鈕/標籤文字則刻意不強制使用
/// 楷體，改用系統預設字型以維持小字級下的可讀性。
class AppTextTheme {
  AppTextTheme._();

  static const String guaFontFamily = 'cwTeXKai';

  /// 卦名標題，例如「乾為天」。
  static const TextStyle guaTitleStyle = TextStyle(
    fontFamily: guaFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
    height: 1.4,
  );

  /// 卦辭 / 爻辭內文。
  static const TextStyle guaCiStyle = TextStyle(
    fontFamily: guaFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    height: 1.8,
  );

  /// 介面按鈕、標籤等一般 UI 文字，不指定 fontFamily 以沿用系統預設字型。
  static const TextStyle uiLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// App 預設 TextTheme：所有標準文字插槽套用 cwTeXKai。
  static TextTheme get textTheme =>
      const TextTheme().apply(fontFamily: guaFontFamily);
}
