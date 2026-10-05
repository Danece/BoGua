import 'package:flutter/foundation.dart';

import '../../data/models/yao_explain.dart';
import 'gua_calculator.dart' show kYaoNames;

/// 單一爻的完整解釋，資料結構本身不含畫面顯示邏輯（留給 Phase 3）。
@immutable
class YaoExplanation {
  const YaoExplanation({
    required this.stage,
    required this.position,
    required this.meaning,
    required this.advice,
    required this.judgementLabel,
    required this.judgementText,
    required this.actionItems,
  });

  /// 爻位階段，例如「巔峰期」。來自 yaoExplainGeneral，與吉凶象無關。
  final String stage;

  /// 爻位描述，例如「尊位」。
  final String position;

  /// 爻位意涵。
  final String meaning;

  /// 爻位通用建議（來自 yaoExplainGeneral，與吉凶象無關）。
  final String advice;

  /// 依爻辭關鍵字判斷出的吉凶象標籤，例如「大吉之象」。
  final String judgementLabel;

  /// 吉凶判斷段落文字。
  final String judgementText;

  /// 行動指引清單，每項已標記「【可行】」或「【不宜】」。
  final List<String> actionItems;
}

/// 1:1 移植自原網頁 yijing-divination-final.html 的 `getYaoExplanation()`
/// 邏輯：先用爻位索引查通用階段資料，再依爻辭關鍵字判斷吉凶象。
class YaoExplainer {
  const YaoExplainer({required this.yaoExplainGeneral});

  /// 爻位（"上爻" ~ "初爻"）→ 通用階段解釋，來自 yao_explain_general.json。
  final Map<String, YaoExplain> yaoExplainGeneral;

  /// [yaoIndex] 為爻位索引（0=上爻...5=初爻），[yaoText] 為該爻的爻辭文字。
  YaoExplanation explain({required int yaoIndex, required String yaoText}) {
    final yaoName = kYaoNames[yaoIndex];
    final general = yaoExplainGeneral[yaoName];
    if (general == null) {
      throw ArgumentError('找不到「$yaoName」的爻位通用解釋資料');
    }

    final category = _classify(yaoText);

    return YaoExplanation(
      stage: general.stage,
      position: general.position,
      meaning: general.meaning,
      advice: general.advice,
      judgementLabel: category.label,
      judgementText: category.judgementText,
      actionItems: category.actionItems,
    );
  }

  /// 依爻辭關鍵字依序判斷吉凶象，符合第一個條件即停止。
  _YaoCategory _classify(String yaoText) {
    final containsXiong = yaoText.contains('凶');
    final containsJi = yaoText.contains('吉');
    final containsWuJiu = yaoText.contains('無咎');
    final containsLiOrWei = yaoText.contains('厲') || yaoText.contains('危');
    final containsLi = yaoText.contains('利');

    if (!containsXiong && containsJi) return _daJi;
    if (containsXiong) return _xiongXian;
    if (containsWuJiu) return _wuJiu;
    if (containsLiOrWei) return _weiLi;
    if (containsLi) return _youLi;
    return _pingWen;
  }

  static const _daJi = _YaoCategory(
    label: '大吉之象',
    judgementText: '此爻辭吉多凶少，乃大吉之象。時運亨通，所求之事多能如願，宜把握良機，順勢而為。',
    actionItems: [
      '【可行】把握眼前機會，積極推動計畫',
      '【可行】廣結善緣，尋求貴人相助',
      '【不宜】驕傲自滿，需知盛極而衰之理',
    ],
  );

  static const _xiongXian = _YaoCategory(
    label: '凶險之象',
    judgementText: '此爻辭示警明顯，乃凶險之象。時運欠佳，貿然行事恐招致損失，宜謹言慎行，以守待變。',
    actionItems: [
      '【不宜】躁進冒險，勉強行事',
      '【不宜】與人爭執衝突，樹立敵對',
      '【可行】退守觀望，靜待時機好轉',
    ],
  );

  static const _wuJiu = _YaoCategory(
    label: '無咎之象',
    judgementText: '此爻辭雖無明顯吉凶斷語，但言明「無咎」，乃可平安無過之象。只要行事合乎正道，便不致招來災咎。',
    actionItems: [
      '【可行】按部就班，依循常理行事',
      '【可行】檢視自身言行，補正缺失',
      '【不宜】投機取巧，妄求僥倖',
    ],
  );

  static const _weiLi = _YaoCategory(
    label: '危厲之象',
    judgementText: '此爻辭含有警惕之意，乃危厲之象。雖未必凶險，但潛藏風險不可輕忽，宜提高警覺，謹慎應對。',
    actionItems: [
      '【可行】提前規劃因應之道，防患未然',
      '【可行】諮詢他人意見，避免獨斷',
      '【不宜】掉以輕心，忽視潛在風險',
    ],
  );

  static const _youLi = _YaoCategory(
    label: '有利之象',
    judgementText: '此爻辭指出有利之處，乃有利之象。時機大致順遂，只要方向正確，多能有所收穫。',
    actionItems: [
      '【可行】朝有利方向積極布局',
      '【可行】把握資源，穩健推進',
      '【不宜】因小利而忽略長遠規劃',
    ],
  );

  static const _pingWen = _YaoCategory(
    label: '平穩之象',
    judgementText: '此爻辭未見明顯吉凶指標，乃平穩之象。事態尚在醞釀，宜保持平常心，順其自然發展。',
    actionItems: [
      '【可行】維持現狀，循序漸進',
      '【可行】持續觀察情勢變化',
      '【不宜】躁動妄為，打亂既有步調',
    ],
  );
}

class _YaoCategory {
  const _YaoCategory({
    required this.label,
    required this.judgementText,
    required this.actionItems,
  });

  final String label;
  final String judgementText;
  final List<String> actionItems;
}
