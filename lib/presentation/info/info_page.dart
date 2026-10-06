import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/divination_history_repository.dart';

/// 系統資訊頁：App 標題／版本、卦象資料來源說明、免責聲明、清除資料入口。
class InfoPage extends ConsumerWidget {
  const InfoPage({super.key});

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部紀錄'),
        content: const Text('確定要刪除所有占卜歷史紀錄嗎？此動作無法復原。'),
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
    if (confirmed != true) return;

    try {
      // 跟歷史紀錄頁共用同一個 notifier，清空後歷史頁的清單狀態也會
      // 一併重新整理，不會出現兩邊不同步的情況。
      await ref.read(divinationHistoryProvider.notifier).clear();
    } catch (error) {
      debugPrint('清空占卜歷史紀錄失敗：$error');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已清空所有占卜歷史紀錄')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('系統資訊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AppHeaderSection(),
            const SizedBox(height: 32),
            const _InfoCard(
              icon: Icons.menu_book_outlined,
              title: '卦象資料來源',
              children: [_SourceInfoBody()],
            ),
            const SizedBox(height: 20),
            const _DisclaimerSection(),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmClearAll(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清除所有資料'),
            ),
          ],
        ),
      ),
    );
  }
}

/// App 標題／版本區塊：八卦符號點綴＋App 名稱＋（非同步載入的）版本號。
class _AppHeaderSection extends StatelessWidget {
  const _AppHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '☰',
          style: TextStyle(
            fontFamily: 'NotoSansSymbols2',
            fontSize: 40,
            height: 1,
            color: AppColors.primaryGlow,
            shadows: AppGlow.shadow(
              AppColors.primaryGlow,
              intensity: 1.5,
            ).cast<Shadow>(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '易經八卦占卜',
          textAlign: TextAlign.center,
          style: AppTextTheme.guaTitleStyle.copyWith(
            fontSize: 26,
            color: AppColors.primaryGlow,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            final text = info == null
                ? '版本載入中…'
                : '版本 v${info.version}（build ${info.buildNumber}）';
            return Text(
              text,
              style: AppTextTheme.uiLabelStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 卦象資料來源區塊的說明文字＋卦數／爻辭數量統計。
class _SourceInfoBody extends StatelessWidget {
  const _SourceInfoBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本App收錄之六十四卦卦辭、爻辭內容，整理自《周易》傳統典籍，'
          '卦辭白話解釋為輔助參考之通俗說明，非學術考據版本。',
          style: AppTextTheme.uiLabelStyle.copyWith(
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _StatChip(label: '卦象', value: '64 卦'),
            _StatChip(label: '爻辭', value: '384 條'),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: AppTextTheme.uiLabelStyle.copyWith(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 免責聲明區塊：用柔和的琥珀色邊框＋圖示跟其他資訊卡片做出區隔，
/// 但不像錯誤／刪除那樣用刺眼的紅色。
class _DisclaimerSection extends StatelessWidget {
  const _DisclaimerSection();

  @override
  Widget build(BuildContext context) {
    const accent = Colors.amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '免責聲明',
                  style: AppTextTheme.uiLabelStyle.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '本App提供之占卜結果僅供參考與自我省思之用，不構成醫療、'
                  '法律、財務或其他專業決策之建議。人生重大決定請諮詢相關'
                  '領域專業人士，理性判斷、審慎行事。',
                  style: AppTextTheme.uiLabelStyle.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 通用的「發光邊框卡片」容器：標題列（圖示＋文字）＋任意內容，跟占卜
/// 結果畫面（[DivinationResultView]）同一套半透明玻璃感視覺語言。
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryGlow),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextTheme.uiLabelStyle.copyWith(
                  color: AppColors.primaryGlow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
