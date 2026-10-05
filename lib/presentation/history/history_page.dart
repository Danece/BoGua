import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';
import '../../data/models/divination_record.dart';
import '../../data/repositories/divination_history_repository.dart';
import '../../domain/logic/gua_calculator.dart';

/// 歷史紀錄列表頁。
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: '清空全部紀錄',
      message: '確定要刪除所有占卜歷史紀錄嗎？此動作無法復原。',
    );
    if (confirmed) {
      try {
        await ref.read(divinationHistoryProvider.notifier).clear();
      } catch (error) {
        debugPrint('清空占卜歷史紀錄失敗：$error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(divinationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('歷史紀錄'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空全部',
            onPressed: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const _EmptyHistoryView();
          }
          return _HistoryList(records: records);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('讀取歷史紀錄失敗：$error', style: AppTextTheme.uiLabelStyle),
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({required this.records});

  final List<DivinationRecord> records;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  // 滑掉的項目先在本地標記隱藏（樂觀更新），避免 Dismissible 在
  // Repository 的非同步刪除真正完成、Provider 重新整理清單之前，
  // 因為項目還留在畫面上而觸發「已滑掉的 Dismissible 仍在畫面中」的錯誤。
  final Set<String> _pendingRemoval = {};

  Future<bool> _confirmDelete(BuildContext context) {
    return _showConfirmDialog(
      context,
      title: '刪除這筆紀錄',
      message: '確定要刪除這筆占卜紀錄嗎？此動作無法復原。',
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.records
        .where((record) => !_pendingRemoval.contains(record.id))
        .toList();

    if (visible.isEmpty) {
      return const _EmptyHistoryView();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = visible[index];
        return Dismissible(
          key: ValueKey(record.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) {
            setState(() => _pendingRemoval.add(record.id));
            unawaited(
              ref
                  .read(divinationHistoryProvider.notifier)
                  .remove(record.id)
                  .catchError((Object error) {
                    debugPrint('刪除占卜歷史紀錄失敗：$error');
                  }),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          child: _HistoryCard(record: record),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final DivinationRecord record;

  @override
  Widget build(BuildContext context) {
    final movingSummary = record.dongYaoIndexes.isEmpty
        ? '無動爻'
        : '動爻：${record.dongYaoIndexes.map((i) => kYaoNames[i]).join('、')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/history/${record.id}'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGlow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: AppColors.primaryGlow, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.benGuaName,
                style: AppTextTheme.guaTitleStyle.copyWith(
                  fontSize: 22,
                  color: AppColors.primaryGlow,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('yyyy/MM/dd HH:mm').format(record.createdAt),
                style: AppTextTheme.uiLabelStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movingSummary,
                style: AppTextTheme.uiLabelStyle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (record.zhiGuaName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '→ 變卦：${record.zhiGuaName}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有占卜紀錄，去問問看吧',
            style: AppTextTheme.uiLabelStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
