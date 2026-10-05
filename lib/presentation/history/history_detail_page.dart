import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';
import '../../data/datasources/gua_data_source.dart';
import '../../data/models/divination_record.dart';
import '../../data/repositories/divination_history_repository.dart';
import '../../domain/logic/gua_calculator.dart';
import '../../domain/logic/yao_explainer.dart';
import '../divination/widgets/divination_result_view.dart';

/// 占卜歷史紀錄詳情頁：把 [DivinationRecord] 重新組裝成
/// [DivinationResult]，重用 [DivinationResultView] 完整重現當次占卜的
/// 結果畫面（本卦／動爻／之卦／占法／判斷依據／解釋）。
class HistoryDetailPage extends ConsumerWidget {
  const HistoryDetailPage({super.key, required this.id});

  final String id;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: '刪除這筆紀錄',
      message: '確定要刪除這筆占卜紀錄嗎？此動作無法復原。',
    );
    if (!confirmed) return;

    try {
      // 重用列表頁的同一個 notifier，刪除後 divinationHistoryProvider 的
      // 清單狀態會一併重新整理，回到列表頁時不會再看到這筆紀錄。
      await ref.read(divinationHistoryProvider.notifier).remove(id);
    } catch (error) {
      debugPrint('刪除占卜歷史紀錄失敗：$error');
    }

    if (context.mounted) {
      context.go('/history');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(divinationRecordProvider(id));
    // riverpod 3.x 的 AsyncValue.value 本身就是安全的 nullable getter
    // （不像 2.x 需要另外呼叫 valueOrNull）。
    final record = recordAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          record == null
              ? '占卜詳情'
              : DateFormat('yyyy/MM/dd HH:mm').format(record.createdAt),
        ),
        actions: [
          if (record != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '刪除這筆紀錄',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return _MessageView(
              icon: Icons.search_off,
              message: '找不到這筆紀錄，可能已經被刪除',
            );
          }
          return _RecordDetailBody(record: record);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _MessageView(icon: Icons.error_outline, message: '讀取失敗：$error'),
      ),
    );
  }
}

/// 已經有 [DivinationRecord] 的情況下，再載入卦象靜態資料，組出
/// [DivinationResultView] 需要的完整輸入。
class _RecordDetailBody extends ConsumerWidget {
  const _RecordDetailBody({required this.record});

  final DivinationRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSourceAsync = ref.watch(guaDataSourceProvider);

    return dataSourceAsync.when(
      data: (dataSource) {
        // DivinationResultView 的輸入介面本來就是「已經算好的資料」
        // （DivinationResult + 靜態卦象資料 + calculator 僅用來查卦象
        // 符號），不會重新呼叫 GuaCalculator.calculate()，所以即時占卜
        // 結果與歷史紀錄回放都能共用同一個元件。
        final calculator = GuaCalculator(
          wheelSegments: dataSource.wheelSegments,
          segmentsMap: dataSource.segmentsMap,
          guaMap: dataSource.guaMap,
          guaCi: dataSource.guaCi,
          guaYaoData: dataSource.guaYaoData,
        );
        final yaoExplainer = YaoExplainer(
          yaoExplainGeneral: dataSource.yaoExplainGeneral,
        );

        final result = _resultFromRecord(record);
        final judgementYaoIndex = judgementYaoIndexFor(record.dongYaoIndexes);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DivinationResultView(
                result: result,
                guaCi: dataSource.guaCi,
                guaYaoData: dataSource.guaYaoData,
                calculator: calculator,
                yaoExplanation: judgementYaoIndex == null
                    ? null
                    : yaoExplainer.explain(
                        yaoIndex: judgementYaoIndex,
                        yaoText: record.judgementText,
                      ),
              ),
              if (record.note != null) ...[
                const SizedBox(height: 20),
                _NoteSection(note: record.note!),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('資料載入失敗：$error', style: AppTextTheme.uiLabelStyle),
      ),
    );
  }

  /// 把已經計算好、存進資料庫的 [DivinationRecord] 轉換回
  /// [DivinationResult] 顯示格式，不需要（也無法）重新呼叫
  /// [GuaCalculator.calculate]——角度等原始輸入沒有被保存下來。
  DivinationResult _resultFromRecord(DivinationRecord record) {
    final judgementYaoIndex = judgementYaoIndexFor(record.dongYaoIndexes);
    return DivinationResult(
      benGuaKey: record.benGuaKey,
      benGuaName: record.benGuaName,
      zhiGuaKey: record.zhiGuaKey,
      zhiGuaName: record.zhiGuaName,
      dongYaoIndexes: record.dongYaoIndexes,
      yaosRaw: record.yaosRaw,
      yaosClean: record.yaosRaw
          .map((yao) => yao.replaceAll('*', ''))
          .toList(growable: false),
      interpretation: record.interpretation,
      judgementYaoText: judgementYaoIndex == null
          ? null
          : kYaoNames[judgementYaoIndex],
      judgementExplain: record.judgementText,
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 備註',
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.primaryGlow,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          note,
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 查無資料或讀取失敗時顯示的提示畫面，提供返回列表頁的按鈕。
class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextTheme.uiLabelStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回列表頁'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('確定'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
