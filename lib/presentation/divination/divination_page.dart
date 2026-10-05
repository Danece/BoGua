import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';
import '../../data/datasources/gua_data_source.dart';
import '../../data/models/divination_record.dart';
import '../../data/repositories/divination_history_repository.dart';
import '../../domain/logic/gua_calculator.dart';
import '../../domain/logic/yao_explainer.dart';
import 'widgets/divination_result_view.dart';
import 'widgets/hexagram_wheel.dart';

/// 占卜主畫面（底部導覽預設頁）。
class DivinationPage extends ConsumerWidget {
  const DivinationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSourceAsync = ref.watch(guaDataSourceProvider);

    return Scaffold(
      body: SafeArea(
        child: dataSourceAsync.when(
          data: (dataSource) => _DivinationBody(dataSource: dataSource),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('資料載入失敗：$error', style: AppTextTheme.uiLabelStyle),
          ),
        ),
      ),
    );
  }
}

class _DivinationBody extends ConsumerStatefulWidget {
  const _DivinationBody({required this.dataSource});

  final GuaDataSource dataSource;

  @override
  ConsumerState<_DivinationBody> createState() => _DivinationBodyState();
}

class _DivinationBodyState extends ConsumerState<_DivinationBody> {
  static const _uuid = Uuid();

  late final GuaCalculator _calculator = GuaCalculator(
    wheelSegments: widget.dataSource.wheelSegments,
    segmentsMap: widget.dataSource.segmentsMap,
    guaMap: widget.dataSource.guaMap,
    guaCi: widget.dataSource.guaCi,
    guaYaoData: widget.dataSource.guaYaoData,
  );

  late final YaoExplainer _yaoExplainer = YaoExplainer(
    yaoExplainGeneral: widget.dataSource.yaoExplainGeneral,
  );

  DivinationResult? _result;

  void _handleResult(DivinationResult result) {
    setState(() => _result = result);

    final record = DivinationRecord(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      benGuaKey: result.benGuaKey,
      benGuaName: result.benGuaName ?? result.benGuaKey,
      zhiGuaKey: result.zhiGuaKey,
      zhiGuaName: result.zhiGuaName,
      dongYaoIndexes: result.dongYaoIndexes,
      yaosRaw: result.yaosRaw,
      interpretation: result.interpretation,
      judgementText: result.judgementExplain,
      explanation: widget.dataSource.guaCi[result.benGuaKey]?.explain ?? '',
    );

    // 寫入歷史紀錄是次要的附帶效果，失敗（例如 sqflite 在 Web 平台
    // 沒有原生實作）不應該影響或中斷占卜結果本身的顯示。
    unawaited(
      ref
          .read(divinationHistoryProvider.notifier)
          .add(record)
          .catchError((Object error) {
            debugPrint('寫入占卜歷史紀錄失敗：$error');
          }),
    );
  }

  void _handleReset() {
    setState(() => _result = null);
  }

  /// 只有一/二/四/五爻變時才有單一判斷爻位，才能交給 [YaoExplainer] 解釋；
  /// 三爻變、六爻變、無動爻沒有單一爻位可解釋。
  YaoExplanation? _yaoExplanationFor(DivinationResult result) {
    final yaoName = result.judgementYaoText;
    if (yaoName == null) return null;

    final yaoIndex = kYaoNames.indexOf(yaoName);
    if (yaoIndex == -1) return null;

    return _yaoExplainer.explain(
      yaoIndex: yaoIndex,
      yaoText: result.judgementExplain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const _TitleSection(),
          const SizedBox(height: 16),
          const _InstructionPanel(),
          const SizedBox(height: 40),
          Center(
            child: ConstrainedBox(
              // 限制最大寬度，避免在平板／桌面等寬螢幕下 AspectRatio(1)
              // 撐滿整個寬度，把版面拉得極高、要捲很久才看得到轉盤。
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: HexagramWheel(
                    calculator: _calculator,
                    onResult: _handleResult,
                    onReset: _handleReset,
                  ),
                ),
              ),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 24),
            DivinationResultView(
              result: result,
              guaCi: widget.dataSource.guaCi,
              guaYaoData: widget.dataSource.guaYaoData,
              calculator: _calculator,
              yaoExplanation: _yaoExplanationFor(result),
            ),
          ],
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '易經占卜',
          style: AppTextTheme.guaTitleStyle.copyWith(
            color: AppColors.primaryGlow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '心誠則靈',
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('使用說明', style: AppTextTheme.uiLabelStyle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '誠心默念所求之事，點擊中央『問』字開始占卜，靜待六爻顯現',
            style: AppTextTheme.guaCiStyle,
          ),
        ],
      ),
    );
  }
}
