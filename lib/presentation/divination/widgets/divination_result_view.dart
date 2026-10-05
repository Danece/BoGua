import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/gua_ci.dart';
import '../../../domain/logic/gua_calculator.dart';
import '../../../domain/logic/yao_explainer.dart';

const Color _kJudgementGold = Color(0xFFFFD700);

/// 顯示一次占卜的完整結果，對應網頁版「本卦／動爻／之卦／占法／
/// 判斷依據／解釋」的資訊架構。掛載時會有一個從下方 20px 滑入
/// 並淡入（約 400ms）的進場動畫。
class DivinationResultView extends StatefulWidget {
  const DivinationResultView({
    super.key,
    required this.result,
    required this.guaCi,
    required this.guaYaoData,
    required this.calculator,
    this.yaoExplanation,
  });

  final DivinationResult result;
  final Map<String, GuaCi> guaCi;
  final Map<String, List<String>> guaYaoData;
  final GuaCalculator calculator;

  /// 判斷依據對應單一爻位時（一/二/四/五爻變）才會有值；
  /// 三爻變、六爻變、無動爻時沒有單一爻位可解釋，維持 null。
  final YaoExplanation? yaoExplanation;

  @override
  State<DivinationResultView> createState() => _DivinationResultViewState();
}

class _DivinationResultViewState extends State<DivinationResultView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 20 / 400),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGlow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: AppColors.primaryGlow, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuaSection(
                emoji: '📖',
                title: '本卦',
                guaKey: result.benGuaKey,
                guaName: result.benGuaName ?? result.benGuaKey,
                trigramSymbols: widget.calculator.trigramSymbolsForKey(
                  result.benGuaKey,
                ),
                guaCi: widget.guaCi[result.benGuaKey],
                yaoTexts: widget.guaYaoData[result.benGuaKey],
                // 本卦：動爻位置標示為醒目色。
                highlightedYaoIndexes: result.dongYaoIndexes.toSet(),
              ),
              const SizedBox(height: 20),
              _MovingYaoSection(result: result),
              if (result.zhiGuaKey != null) ...[
                const SizedBox(height: 20),
                _GuaSection(
                  emoji: '🔄',
                  title: '之卦（變卦）',
                  guaKey: result.zhiGuaKey!,
                  guaName: result.zhiGuaName ?? result.zhiGuaKey!,
                  trigramSymbols: widget.calculator.trigramSymbolsForKey(
                    result.zhiGuaKey!,
                  ),
                  guaCi: widget.guaCi[result.zhiGuaKey!],
                  yaoTexts: widget.guaYaoData[result.zhiGuaKey!],
                  // 之卦：未變的爻才標示為醒目色（原網頁邏輯）。
                  highlightedYaoIndexes: {
                    for (var i = 0; i < 6; i++)
                      if (!result.dongYaoIndexes.contains(i)) i,
                  },
                ),
              ],
              const SizedBox(height: 20),
              _LabeledText(emoji: '🎯', label: '占法', text: result.interpretation),
              const SizedBox(height: 12),
              _LabeledText(
                emoji: '📜',
                label: '判斷依據',
                text: result.judgementExplain,
                textColor: _kJudgementGold,
              ),
              if (widget.yaoExplanation != null) ...[
                const SizedBox(height: 20),
                _ExplanationSection(explanation: widget.yaoExplanation!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuaSection extends StatelessWidget {
  const _GuaSection({
    required this.emoji,
    required this.title,
    required this.guaKey,
    required this.guaName,
    required this.trigramSymbols,
    required this.guaCi,
    required this.yaoTexts,
    required this.highlightedYaoIndexes,
  });

  final String emoji;
  final String title;
  final String guaKey;
  final String guaName;
  final List<String> trigramSymbols;
  final GuaCi? guaCi;
  final List<String>? yaoTexts;
  final Set<int> highlightedYaoIndexes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(emoji: emoji, label: title),
        const SizedBox(height: 8),
        Text(
          guaName,
          style: AppTextTheme.guaTitleStyle.copyWith(
            fontSize: 22,
            color: AppColors.primaryGlow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '上卦 ${trigramSymbols[0]}　下卦 ${trigramSymbols[1]}',
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (guaCi != null) ...[
          const SizedBox(height: 12),
          Text(
            guaCi!.ci,
            style: AppTextTheme.guaCiStyle.copyWith(color: _kJudgementGold),
          ),
          const SizedBox(height: 8),
          Text(
            guaCi!.explain,
            style: AppTextTheme.uiLabelStyle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (yaoTexts != null) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < yaoTexts!.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${kYaoNames[i]}：${yaoTexts![i]}',
                style: highlightedYaoIndexes.contains(i)
                    ? AppTextTheme.uiLabelStyle.copyWith(
                        color: _kJudgementGold,
                        fontWeight: FontWeight.bold,
                      )
                    : AppTextTheme.uiLabelStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MovingYaoSection extends StatelessWidget {
  const _MovingYaoSection({required this.result});

  final DivinationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(emoji: '⚡', label: '動爻'),
        const SizedBox(height: 8),
        if (result.dongYaoIndexes.isEmpty)
          Text(
            '無動爻',
            style: AppTextTheme.uiLabelStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else ...[
          Text(
            result.dongYaoIndexes.map((i) => kYaoNames[i]).join('、'),
            style: AppTextTheme.uiLabelStyle.copyWith(
              color: AppColors.primaryGlow,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.dongYaoIndexes
                .map((i) => result.yaosRaw[i])
                .join('　'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({required this.explanation});

  final YaoExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(emoji: '💡', label: '解釋'),
        const SizedBox(height: 8),
        Text(
          '${explanation.stage}｜${explanation.position}｜${explanation.meaning}',
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          explanation.judgementLabel,
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.primaryGlow,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          explanation.judgementText,
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in explanation.actionItems) _ActionItem(text: item),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isFeasible = text.startsWith('【可行】');
    final isInfeasible = text.startsWith('【不宜】');
    final label = text
        .replaceFirst('【可行】', '')
        .replaceFirst('【不宜】', '')
        .trim();

    final icon = isFeasible
        ? Icons.check_circle
        : (isInfeasible ? Icons.cancel : Icons.circle);
    final color = isFeasible
        ? AppColors.primaryGlow
        : (isInfeasible ? Colors.redAccent : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextTheme.uiLabelStyle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.emoji,
    required this.label,
    required this.text,
    this.textColor,
  });

  final String emoji;
  final String label;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(emoji: emoji, label: label),
        const SizedBox(height: 8),
        Text(
          text,
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$emoji $label',
      style: AppTextTheme.uiLabelStyle.copyWith(
        color: AppColors.primaryGlow,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
