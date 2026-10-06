import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/logic/gua_calculator.dart';

/// 六層同心圓轉盤，由外而內依序對應 [kWheelSegmentKeys]：
/// 上爻、五爻、四爻、三爻、二爻、初爻。
///
/// 視覺結構是 6 個「各自獨立、由大到小疊放」的實心圓形圖層（見
/// [RingLayer]），不是用單一 CustomPainter 畫出一整圈弧線：小圖層天生
/// 會蓋住大圖層的中心，只露出一圈環狀帶，環狀帶上各自畫著純裝飾用的
/// 分隔線與固定圖案（跟 [GuaCalculator] 實際占卜用的 wheelSegments
/// 資料無關）。
///
/// 點擊中央按鈕會讓六層各自轉動到一個獨立的隨機角度，全部停止後用
/// [calculator] 計算占卜結果並透過 [onResult] 回傳；結果狀態下再次點擊
/// （此時按鈕顯示 [centerResetLabel]）會讓轉盤轉回 0 度並透過 [onReset]
/// 通知外部清空結果畫面。
class HexagramWheel extends StatefulWidget {
  const HexagramWheel({
    super.key,
    required this.calculator,
    this.onResult,
    this.onReset,
    this.centerIdleLabel = '問',
    this.centerResetLabel = '重置',
  });

  final GuaCalculator calculator;
  final ValueChanged<DivinationResult>? onResult;
  final VoidCallback? onReset;

  final String centerIdleLabel;
  final String centerResetLabel;

  @override
  State<HexagramWheel> createState() => HexagramWheelState();
}

enum _WheelStatus { idle, spinning, result }

class HexagramWheelState extends State<HexagramWheel>
    with TickerProviderStateMixin {
  static const int _ringCount = 6;
  static const Duration _spinDuration = Duration(seconds: 9);
  static const Duration _resetDuration = Duration(milliseconds: 300);

  /// 轉盤最大直徑的上限（邏輯像素），依螢幕寬度自適應但不超過這個值。
  static const double _maxDiameter = 350;

  /// 中央按鈕直徑相對於轉盤最大直徑（wheel 層）的比例，對應原網頁
  /// 80px/700px 的比例。要明顯小於最內層 inner2（[RingLayer.layerRatios]
  /// 的 2/7 ≈ 0.286），inner2 自己的裝飾文字才有完整的環狀空間可以顯示，
  /// 不會被按鈕蓋住。
  static const double _centerButtonRatio = 0.114;

  late final List<AnimationController> _controllers = List.generate(
    _ringCount,
    (_) => AnimationController(vsync: this),
  );

  final List<double> _currentAngles = List.filled(_ringCount, 0);
  List<Animation<double>> _ringAnimations = List.filled(
    _ringCount,
    const AlwaysStoppedAnimation<double>(0),
  );

  _WheelStatus _status = _WheelStatus.idle;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startSpin() async {
    if (_status != _WheelStatus.idle) return;
    setState(() => _status = _WheelStatus.spinning);

    final random = math.Random();
    final animations = <Animation<double>>[];
    for (var i = 0; i < _ringCount; i++) {
      final controller = _controllers[i]
        ..duration = _spinDuration
        ..reset();
      final direction = random.nextBool() ? 1.0 : -1.0;
      final delta = direction * random.nextDouble() * 3600;
      final animation =
          Tween<double>(
            begin: _currentAngles[i],
            end: _currentAngles[i] + delta,
          ).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOut),
          );
      animations.add(animation);
    }
    setState(() => _ringAnimations = animations);

    await Future.wait(_controllers.map((controller) => controller.forward()));
    if (!mounted) return;

    for (var i = 0; i < _ringCount; i++) {
      _currentAngles[i] = normalizeAngleDegrees(animations[i].value);
    }

    final result = widget.calculator.calculate(List.of(_currentAngles));

    setState(() => _status = _WheelStatus.result);
    widget.onResult?.call(result);
  }

  Future<void> _reset() async {
    if (_status != _WheelStatus.result) return;

    final animations = <Animation<double>>[];
    for (var i = 0; i < _ringCount; i++) {
      final controller = _controllers[i]
        ..duration = _resetDuration
        ..reset();
      final animation = Tween<double>(begin: _currentAngles[i], end: 0)
          .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
      animations.add(animation);
    }
    setState(() => _ringAnimations = animations);

    await Future.wait(_controllers.map((controller) => controller.forward()));
    if (!mounted) return;

    for (var i = 0; i < _ringCount; i++) {
      _currentAngles[i] = 0;
    }
    setState(() => _status = _WheelStatus.idle);
    widget.onReset?.call();
  }

  void _onCenterTap() {
    switch (_status) {
      case _WheelStatus.idle:
        _startSpin();
      case _WheelStatus.spinning:
        break;
      case _WheelStatus.result:
        _reset();
    }
  }

  String get _centerLabel {
    switch (_status) {
      case _WheelStatus.idle:
        return widget.centerIdleLabel;
      case _WheelStatus.spinning:
        return '';
      case _WheelStatus.result:
        return widget.centerResetLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 依可用寬度的 95% 自適應，但設定上限避免在平板／桌面等寬螢幕
        // 下長到超出可視高度被裁切。
        final diameter = (constraints.maxWidth * 0.95).clamp(
          0.0,
          _maxDiameter,
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // 六層由大到小疊放：外層在下、內層在上，小圖層的不透明底色
            // 會自然蓋住大圖層的中心，只露出一圈環狀帶（見 RingLayer 的
            // 文件註解）。旋轉用 Transform.rotate 包在最外層——它是純
            // 合成層變換，不會讓裡面的 RepaintBoundary 內容重新繪製，只
            // 有轉出來的角度會變。
            for (var ring = 0; ring < _ringCount; ring++)
              AnimatedBuilder(
                animation: _controllers[ring],
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _ringAnimations[ring].value * math.pi / 180,
                    child: RepaintBoundary(
                      child: RingLayer(
                        diameter: diameter * RingLayer.layerRatios[ring],
                        ringIndex: ring,
                      ),
                    ),
                  );
                },
              ),
            RepaintBoundary(
              child: _CenterButton(
                diameter: diameter * _centerButtonRatio,
                label: _centerLabel,
                loading: _status == _WheelStatus.spinning,
                onTap: _status == _WheelStatus.spinning ? null : _onCenterTap,
              ),
            ),
            // 太極指標：固定在正上方 12 點鐘、完全不隨任何一層轉盤旋轉，
            // 放在 Stack 最後（z 軸最高），蓋過所有轉盤層與中央按鈕。
            // 結果出來後改用金黃色標示已完成占問，重置／重新發問時變回
            // 原本的青綠發光色。
            RepaintBoundary(
              child: _TopIndicator(
                diameter: diameter,
                color: _status == _WheelStatus.result
                    ? AppColors.resultGold
                    : AppColors.primaryGlow,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 單一層轉盤的靜態視覺內容：一個不透明的實心圓形容器（primaryGlow 邊框
/// ＋發光＋backgroundDark 底色），上面疊放 3 條穿過圓心的分隔線（合計
/// 6 條放射狀分隔線）與 6 個固定的裝飾圖案文字。
///
/// 純粹是裝飾用的靜態畫面，跟 [GuaCalculator] 實際占卜依據的
/// wheelSegments（⚊/⚋ 資料）完全無關，不會隨占卜結果改變；圖案內容依
/// [ringIndex]（0=上爻...5=初爻）查表決定。旋轉不是這個元件的職責——外
/// 層呼叫端用 [Transform.rotate] 包住整個 [RingLayer] 來轉動它。
class RingLayer extends StatelessWidget {
  const RingLayer({super.key, required this.diameter, required this.ringIndex});

  /// 這一層自己的直徑（已經乘過 [layerRatios] 的比例）。
  final double diameter;

  /// 第幾層，0=上爻（最外層 wheel）...5=初爻（最內層 inner2）。
  final int ringIndex;

  /// 六層由外而內（上爻→初爻）各自的直徑比例，相對於轉盤最大直徑：
  /// wheel(1.0) → outter3(6/7) → outter2(5/7) → outter(4/7) →
  /// inner(3/7) → inner2(2/7)。
  static const List<double> layerRatios = [
    1.0,
    6 / 7,
    5 / 7,
    4 / 7,
    3 / 7,
    2 / 7,
  ];

  /// 六層各自固定的裝飾文字（三字圖案），依 [ringIndex] 查表、依扇形區塊
  /// 索引（0~5，順時針、從 12 點鐘方向起算）排列。純視覺裝飾，跟真實占卜
  /// 資料完全無關。
  static const List<List<String>> _decorations = [
    ['○○○', '○○●', '○●●', '●●●', '●●○', '●○○'], // wheel（上爻）
    ['○○●', '○●●', '●●●', '●●○', '●○○', '○○○'], // outter3（五爻）
    ['○●●', '●●●', '●●○', '●○○', '○○○', '○○●'], // outter2（四爻）
    ['●●●', '●●○', '●○○', '○○○', '○○●', '○●●'], // outter（三爻）
    ['●●○', '●○○', '○○○', '○○●', '○●●', '●●●'], // inner（二爻）
    ['●○○', '○○○', '○○●', '○●●', '●●●', '●●○'], // inner2（初爻）
  ];

  @override
  Widget build(BuildContext context) {
    final radius = diameter / 2;

    // 裝飾文字放在這一層自己的可視環狀帶內：外緣是自己的邊界，內緣大約
    // 是下一層（更小的那一層）疊上來蓋住的位置；最內層（inner2）沒有
    // 下一層可以查，沿用同樣的等差比例往下推一階作為估計。
    final ownRatio = layerRatios[ringIndex];
    final nextIndex = ringIndex + 1;
    final nextRatio = nextIndex < layerRatios.length
        ? layerRatios[nextIndex]
        : ownRatio - (layerRatios[0] - layerRatios[1]);
    final contentRadius = radius * (1 + nextRatio / ownRatio) / 2;

    final texts = _decorations[ringIndex];

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundDark,
        border: Border.all(color: AppColors.primaryGlow, width: 1.5),
        boxShadow: AppGlow.shadow(AppColors.primaryGlow),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: const _SpokesPainter(),
          ),
          for (var seg = 0; seg < 6; seg++)
            _DecorationLabel(
              text: texts[seg],
              radius: contentRadius,
              // 6 個扇形區塊的正中央跟分隔線錯開 30°。
              angleDegrees: seg * 60.0 + 30.0,
            ),
        ],
      ),
    );
  }
}

/// 一個裝飾圖案文字，用極座標（[radius]、[angleDegrees]）定位在圓心
/// 外圍；文字本身也會跟著轉到對應角度（不強制轉正），視覺上像真的印在
/// 轉盤圓周上的圖案。
class _DecorationLabel extends StatelessWidget {
  const _DecorationLabel({
    required this.text,
    required this.radius,
    required this.angleDegrees,
  });

  final String text;
  final double radius;

  /// 0° = 12 點鐘方向，順時針遞增。
  final double angleDegrees;

  @override
  Widget build(BuildContext context) {
    final radians = (angleDegrees - 90) * math.pi / 180;
    final offset = Offset(radius * math.cos(radians), radius * math.sin(radians));

    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        // 文字頂端朝外（沿半徑方向），跟著這一段的角度轉，不強制轉正。
        angle: radians + math.pi / 2,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGlow,
          ),
        ),
      ),
    );
  }
}

/// 畫 3 條穿過圓心、分別旋轉 0°／60°／120° 的直徑線（合計 6 條放射狀
/// 分隔線）。純靜態內容，不依賴任何外部狀態，[shouldRepaint] 永遠回傳
/// false。
class _SpokesPainter extends CustomPainter {
  const _SpokesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final glowPaint = Paint()
      ..color = AppColors.primaryGlow.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final linePaint = Paint()
      ..color = AppColors.primaryGlow.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      // 0° 對齊 12-6 點鐘方向，再依序旋轉 60°、120°。
      final angle = (i * 60 - 90) * math.pi / 180;
      final delta = Offset(radius * math.cos(angle), radius * math.sin(angle));
      canvas.drawLine(center + delta, center - delta, glowPaint);
      canvas.drawLine(center + delta, center - delta, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpokesPainter oldDelegate) => false;
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.diameter,
    required this.label,
    required this.loading,
    this.onTap,
  });

  final double diameter;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 按鈕現在只有轉盤最大直徑的 11.4%（明顯小於最內層 inner2，見
    // HexagramWheelState._centerButtonRatio），guaTitleStyle 固定
    // 32px／4 letterSpacing 的字級會直接把「重置」兩個字撐出圓形按鈕，
    // 所以字級、letterSpacing、邊框都改成跟 diameter 等比例縮放。
    final fontSize = (diameter * 0.32).clamp(10.0, 32.0);
    final borderWidth = (diameter * 0.05).clamp(1.0, 2.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: loading ? 0.3 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundDark,
            border: Border.all(
              color: AppColors.primaryGlow,
              width: borderWidth,
            ),
            boxShadow: AppGlow.shadow(AppColors.primaryGlow, intensity: 1.5),
          ),
          child: Text(
            label,
            style: AppTextTheme.guaTitleStyle.copyWith(
              fontSize: fontSize,
              letterSpacing: fontSize * 0.05,
              color: AppColors.primaryGlow,
              shadows: AppGlow.shadow(
                AppColors.primaryGlow,
                intensity: 1.5,
              ).cast<Shadow>(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 固定在轉盤正上方（12 點鐘方向、最外層圓框外側）的太極指標，完全不
/// 隨任何一層轉盤旋轉——不管轉盤怎麼轉，它永遠指向正上方。由上到下是
/// 「☯ 符號 + 一條會呼吸明暗的指標線」，整組視覺上像「站在轉盤正上方
/// 指向轉盤」。
///
/// [diameter] 是最外層（wheel）轉盤的直徑，用來把這個指標對齊到跟轉盤
/// 同一個中心、同一個縮放比例；指標本身的大小另外用比例算，不受六層
/// 轉盤的縮放比例（[RingLayer.layerRatios]）影響。
class _TopIndicator extends StatefulWidget {
  const _TopIndicator({required this.diameter, required this.color});

  final double diameter;

  /// ☯ 符號與指標線目前該用的顏色，由外部依占卜狀態決定（見
  /// [HexagramWheelState.build]）：idle／spinning 用原本的青綠發光色，
  /// result 用金黃色標示已完成占問。這個 widget 本身只負責呈現，不記
  /// 錄狀態，所以顏色切換不需要額外處理——外部傳新的 [color] 進來，
  /// 下一次 build 就會用新顏色重繪。
  final Color color;

  @override
  State<_TopIndicator> createState() => _TopIndicatorState();
}

class _TopIndicatorState extends State<_TopIndicator>
    with SingleTickerProviderStateMixin {
  static const Duration _breathDuration = Duration(seconds: 2);

  late final AnimationController _breathController = AnimationController(
    vsync: this,
    duration: _breathDuration,
  )..repeat(reverse: true);

  late final Animation<double> _breath = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbolSize = (widget.diameter * 0.08).clamp(18.0, 28.0);
    // 指標線下端深入的深度：從最外層轉盤邊緣一路貫穿到最內層
    // （inner2，見 [RingLayer.layerRatios] 最後一項）的外緣，而不是只
    // 淺淺地插進最外層邊框。
    final innerRingRadius = widget.diameter * RingLayer.layerRatios.last / 2;
    final penetration = widget.diameter / 2 - innerRingRadius;
    // 符號下緣跟轉盤外緣之間留的一小段空隙，維持跟原本一致的視覺比例
    // （原本 lineLength 0.09 扣掉 penetration 0.035 的差）。
    final lineLength = widget.diameter * 0.055 + penetration;

    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: Align(
        alignment: Alignment.topCenter,
        // Align 預設把內容頂端貼齊在方框頂端（也就是最外層轉盤的頂端），
        // 這裡再往上平移，讓符號整個露在轉盤外側、指標線下端剛好深入
        // 轉盤邊框內側 [penetration] 那麼多。
        child: Transform.translate(
          offset: Offset(0, -(symbolSize + lineLength - penetration)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '☯',
                style: TextStyle(
                  // 指定內建的單色符號字型；系統預設字型沒有這個字形時，
                  // 會改用彩色 emoji 字型，畫出紫色圖示。
                  fontFamily: 'NotoSansSymbols',
                  fontSize: symbolSize,
                  color: widget.color,
                  shadows: AppGlow.shadow(
                    widget.color,
                    intensity: 1.5,
                  ).cast<Shadow>(),
                ),
              ),
              AnimatedBuilder(
                animation: _breath,
                builder: (context, _) {
                  final breath = _breath.value;
                  return Container(
                    width: 3,
                    height: lineLength,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.color.withValues(alpha: breath),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                      boxShadow: AppGlow.shadow(
                        widget.color,
                        intensity: breath,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
