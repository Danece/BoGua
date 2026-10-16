// 產生 App 圖示原圖：太極居中、外圍一圈先天八卦。
//
// 用 flutter_tester 的 Canvas 畫出 PNG，不需要另外安裝繪圖工具：
//
//   flutter test tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// 第一步輸出到 assets/icon/，第二步依 pubspec.yaml 的 flutter_launcher_icons
// 設定產生 Android／iOS／Web 各尺寸圖示。放在 tool/ 而非 test/，所以一般的
// `flutter test` 不會跑到它。
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiding_the_unknown_path/core/theme/app_colors.dart';

const double _size = 1024;

/// 先天八卦：乾在上，逆時針依序兌、離、震、坤（下）、艮、坎、巽。
/// 每卦三爻由下（內圈）往上（外圈）排，true 為陽爻。
const List<List<bool>> _trigrams = [
  [true, true, true], // 乾
  [true, true, false], // 兌
  [true, false, true], // 離
  [true, false, false], // 震
  [false, false, false], // 坤
  [false, false, true], // 艮
  [false, true, false], // 坎
  [false, true, true], // 巽
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate app icon', () async {
    final outDir = Directory('assets/icon')..createSync(recursive: true);
    // 完整圖示：iOS、Web、舊版 Android 用，含背景。
    await _writePng('${outDir.path}/app_icon.png', scale: 1, withBackground: true);
    // Android adaptive icon 前景：透明背景，內容縮進 66% 安全區內，
    // 避免被各廠牌的圓形／方形遮罩切掉。
    await _writePng(
      '${outDir.path}/app_icon_foreground.png',
      scale: 0.62,
      withBackground: false,
    );
  });
}

Future<void> _writePng(
  String path, {
  required double scale,
  required bool withBackground,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(_size / 2, _size / 2);

  if (withBackground) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _size, _size),
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          _size * 0.7,
          [AppColors.backgroundDark, AppColors.backgroundDarker],
        ),
    );
  }

  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  // 先畫一層模糊版本當光暈，再疊上清晰版本。
  _drawEmblem(canvas, glow: true);
  _drawEmblem(canvas, glow: false);

  final image =
      await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void _drawEmblem(Canvas canvas, {required bool glow}) {
  const color = AppColors.primaryGlow;
  final blur = glow ? const MaskFilter.blur(BlurStyle.normal, 18) : null;
  final light = Paint()
    ..color = glow ? color.withValues(alpha: 0.7) : color
    ..maskFilter = blur;
  final dark = Paint()..color = AppColors.backgroundDarker;

  // ── 太極 ──
  const r = 190.0;
  canvas.drawCircle(Offset.zero, r + 10, light); // 外框
  if (!glow) {
    canvas.drawCircle(Offset.zero, r, dark);
    // 右半為陽；半徑多 1px 蓋掉與外框之間的反鋸齒細縫。
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r + 1),
      -math.pi / 2,
      math.pi,
      true,
      light,
    );
    canvas.drawCircle(const Offset(0, -r / 2), r / 2, light);
    canvas.drawCircle(const Offset(0, r / 2), r / 2, dark);
    canvas.drawCircle(const Offset(0, -r / 2), r / 7, dark);
    canvas.drawCircle(const Offset(0, r / 2), r / 7, light);
  }

  // ── 八卦 ──
  const innerRadius = 270.0;
  const lineGap = 44.0;
  const barHeight = 24.0;
  const barWidth = 150.0;
  const yinGap = 30.0;
  for (var i = 0; i < _trigrams.length; i++) {
    canvas.save();
    // 逆時針排列；Flutter 的正角度是順時針，所以取負。
    canvas.rotate(-i * math.pi / 4);
    for (var j = 0; j < 3; j++) {
      final y = -(innerRadius + j * lineGap);
      final rect = Rect.fromCenter(
        center: Offset(0, y),
        width: barWidth,
        height: barHeight,
      );
      if (_trigrams[i][j]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          light,
        );
      } else {
        final half = (barWidth - yinGap) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left, rect.top, half, barHeight),
            const Radius.circular(4),
          ),
          light,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.right - half, rect.top, half, barHeight),
            const Radius.circular(4),
          ),
          light,
        );
      }
    }
    canvas.restore();
  }
}
