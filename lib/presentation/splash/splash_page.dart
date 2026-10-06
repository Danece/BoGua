import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';
import '../../core/theme/app_theme.dart';

/// 乾兌離震巽坎艮坤，依序排成圓形。
const List<String> _kBaguaSymbols = [
  '☰',
  '☱',
  '☲',
  '☳',
  '☴',
  '☵',
  '☶',
  '☷',
];

/// 進場動畫畫面：星空背景 + 緩慢旋轉的八卦符號 + 發光標題。
///
/// 顯示 3 秒後自動淡出並導向 /divination；使用者也可在 3 秒內點擊畫面
/// 任一處提前跳過。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  static const Duration _displayDuration = Duration(seconds: 3);
  static const Duration _fadeDuration = Duration(milliseconds: 500);
  static const Duration _starCycleDuration = Duration(seconds: 4);
  static const Duration _rotationDuration = Duration(seconds: 9);

  late final List<_Star> _stars = _generateStars();

  late final AnimationController _starController = AnimationController(
    vsync: this,
    duration: _starCycleDuration,
  )..repeat();

  late final AnimationController _rotationController = AnimationController(
    vsync: this,
    duration: _rotationDuration,
  )..repeat();

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: _fadeDuration,
  );

  Timer? _exitTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _exitTimer = Timer(_displayDuration, _startExitSequence);
  }

  List<_Star> _generateStars() {
    final random = math.Random();
    final count = 80 + random.nextInt(21); // 80~100 顆
    return List.generate(count, (_) {
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        radius: 0.5 + random.nextDouble() * 1.8,
        baseOpacity: 0.4 + random.nextDouble() * 0.6,
        // 0~1 的週期分率（非弳度），與 progress 相乘時單位一致，
        // 讓每顆星星的閃爍相位彼此錯開。
        phase: random.nextDouble(),
        frequency: 0.5 + random.nextDouble() * 2.0,
      );
    });
  }

  Future<void> _startExitSequence() async {
    if (_isExiting) return;
    _isExiting = true;
    _exitTimer?.cancel();

    await _fadeController.forward();
    if (mounted) {
      context.go('/divination');
    }
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _starController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startExitSequence,
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(opacity: 1 - _fadeController.value, child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _BackgroundGradient(),
              // RepaintBoundary：星空每個 frame 都在重繪（80~100 顆星星
              // 持續閃爍），獨立成一個合成層，才不會連帶讓底下的背景
              // 漸層、以及同一個 Stack 裡的八卦／標題也跟著重繪。
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _starController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _StarFieldPainter(
                        stars: _stars,
                        progress: _starController.value,
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 同理：旋轉八卦每個 frame 都在重繪，獨立成一層，
                    // 不會連帶讓下面有發光陰影、繪製成本較高的標題文字
                    // 也跟著重繪。
                    RepaintBoundary(
                      child: _RotatingBagua(controller: _rotationController),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '易經占卜',
                      style: AppTextTheme.guaTitleStyle.copyWith(
                        color: AppColors.primaryGlow,
                        shadows: AppGlow.shadow(
                          AppColors.primaryGlow,
                          intensity: 1.5,
                        ).cast<Shadow>(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundDarker, AppColors.backgroundDark],
        ),
      ),
    );
  }
}

class _RotatingBagua extends StatelessWidget {
  const _RotatingBagua({required this.controller});

  final AnimationController controller;

  static const double _size = 200;
  static const double _radius = _size / 2 - 16;
  static const double _center = _size / 2;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Stack(
              children: [
                for (var i = 0; i < _kBaguaSymbols.length; i++) _symbol(i),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _symbol(int index) {
    final angle = (index * 2 * math.pi / _kBaguaSymbols.length) - math.pi / 2;
    final x = _center + _radius * math.cos(angle) - 14;
    final y = _center + _radius * math.sin(angle) - 14;

    return Positioned(
      left: x,
      top: y,
      child: Text(
        _kBaguaSymbols[index],
        style: TextStyle(
          // 指定內建字型，避免網頁版等備援字型下載時先顯示成方框。
          fontFamily: 'NotoSansSymbols2',
          fontSize: 28,
          color: AppColors.primaryGlow,
          shadows: AppGlow.shadow(AppColors.primaryGlow).cast<Shadow>(),
        ),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.baseOpacity,
    required this.phase,
    required this.frequency,
  });

  /// 相對畫布寬度／高度的比例（0~1），畫的時候再乘上實際尺寸。
  final double dx;
  final double dy;
  final double radius;
  final double baseOpacity;

  /// 0~1 的週期分率，讓每顆星星的閃爍起始點不同。
  final double phase;

  /// 相對於 [_SplashPageState._starCycleDuration] 一輪週期的倍率，
  /// 讓每顆星星閃爍的快慢也不同。
  final double frequency;
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.stars, required this.progress});

  final List<_Star> stars;

  /// 0~1 循環的動畫進度。
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      final twinkle =
          0.5 +
          0.5 * math.sin(2 * math.pi * (progress * star.frequency + star.phase));
      final opacity = (star.baseOpacity * (0.3 + 0.7 * twinkle)).clamp(
        0.0,
        1.0,
      );
      paint.color = AppColors.textPrimary.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
