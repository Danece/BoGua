import 'package:flutter/foundation.dart';

import '../../data/models/gua_ci.dart';

/// 六爻名稱，索引 0 對應「上爻」、索引 5 對應「初爻」。
const List<String> kYaoNames = ['上爻', '五爻', '四爻', '三爻', '二爻', '初爻'];

/// 六個轉盤依序對應到 wheel_segments.json 的 key，順序需與 [kYaoNames] 一致。
const List<String> kWheelSegmentKeys = [
  'segments_up',
  'segments_five',
  'segments_four',
  'segments_three',
  'segments_two',
  'segments_first',
];

/// 將角度正規化到 [0, 360) 區間。
///
/// Dart 的 `%` 對正除數已保證回傳非負值（與 JavaScript 對負數取餘會
/// 得到負值不同），這裡仍明確處理以自我說明意圖，並防禦浮點數邊界誤差。
double normalizeAngleDegrees(double angle) {
  final remainder = angle % 360;
  return remainder < 0 ? remainder + 360 : remainder;
}

/// 把轉盤目前的旋轉角度換算成落在哪一個扇形區塊（0~5）。
///
/// 轉盤在畫面上是用 `Transform.rotate` 轉動的：Flutter 的螢幕座標系
/// y 軸朝下，`angle` 為正時視覺上是**順時針**旋轉（跟數學課本慣用、
/// y 軸朝上時「正角度=逆時針」的直覺相反）。固定不動的指標永遠指向
/// 正上方（12 點鐘方向）；轉盤順時針轉了 [rotationDegrees] 度之後，
/// 原本位於「本地角度 -rotationDegrees」的那個區塊，現在才會轉到指標
/// 正下方。所以必須先把角度取負號、再正規化到 [0, 360)，不能直接對
/// 原始角度正規化——這個負號就是先前版本的 bug 所在。
///
/// 六個轉盤（上爻~初爻）都呼叫這同一個函式取得區塊索引，不會各自
/// 複製一份公式。
///
/// 這個「正角度＝順時針」的假設本身已經用
/// test/presentation/divination/hexagram_wheel_rotation_test.dart
/// 的一個獨立測試直接量測 `Transform.rotate` 的實際渲染結果驗證過，
/// 不是憑感覺假設的。
int angleToSegmentIndex(double rotationDegrees) {
  final normalized = normalizeAngleDegrees(-rotationDegrees);
  return (normalized / 60).floor().clamp(0, 5);
}

/// 一次占卜運算的完整結果。
@immutable
class DivinationResult {
  const DivinationResult({
    required this.benGuaKey,
    required this.benGuaName,
    required this.zhiGuaKey,
    required this.zhiGuaName,
    required this.dongYaoIndexes,
    required this.yaosRaw,
    required this.yaosClean,
    required this.interpretation,
    required this.judgementYaoText,
    required this.judgementExplain,
  });

  /// 本卦代碼，例如 "14"。
  final String benGuaKey;

  /// 本卦顯示名稱（來自 guaMap），例如 "䷛ 大過卦-澤風大過"。
  final String? benGuaName;

  /// 之卦代碼；無動爻時為 null。
  final String? zhiGuaKey;

  /// 之卦顯示名稱；無動爻時為 null。
  final String? zhiGuaName;

  /// 動爻索引（0=上爻...5=初爻），由小到大排序。
  final List<int> dongYaoIndexes;

  /// 六爻原始符號（含 "*" 動爻標記），索引 0=上爻...5=初爻。
  final List<String> yaosRaw;

  /// 六爻乾淨符號（不含 "*"），索引 0=上爻...5=初爻。
  final List<String> yaosClean;

  /// 占法描述文字，例如「一爻變，本卦 上爻 爻辭占」。
  final String interpretation;

  /// 判斷依據所在的爻名（例如「上爻」）；無特定單一爻辭時為 null。
  final String? judgementYaoText;

  /// 判斷依據的實際文字內容（卦辭或爻辭）。
  final String judgementExplain;
}

/// 依動爻數量計算「判斷依據」對應的單一爻位索引（0=上爻...5=初爻）。
///
/// 僅一／二／四／五爻變時才有單一爻位可對應；零／三／六爻變是以本卦或
/// 之卦「卦辭」（而非單一爻辭）合占，回傳 null。邏輯與
/// [GuaCalculator._interpret] 的爻位選擇規則完全一致，抽成獨立的純函式，
/// 讓由歷史紀錄回放（DivinationRecord 只存了計算後的結果，無法重新
/// 呼叫 [GuaCalculator.calculate]）重組 [DivinationResult] 時也能共用。
int? judgementYaoIndexFor(List<int> dongYaoIndexes) {
  switch (dongYaoIndexes.length) {
    case 1:
      return dongYaoIndexes.single;
    case 2:
      // 動爻索引依建構順序（0..5）遞增排列，取較小者即為位階較高者。
      return dongYaoIndexes.first;
    case 4:
      // 不變的兩爻中，索引較大者位階較低。
      return _unchangedIndexesOf(dongYaoIndexes).last;
    case 5:
      return _unchangedIndexesOf(dongYaoIndexes).single;
    default:
      return null;
  }
}

List<int> _unchangedIndexesOf(List<int> dongYaoIndexes) {
  return [
    for (var i = 0; i < 6; i++)
      if (!dongYaoIndexes.contains(i)) i,
  ];
}

/// 1:1 移植自原網頁 yijing-divination-final.html 的
/// `calculateZhiGua()` 與 `getInterpretation()` 占卜運算邏輯。
class GuaCalculator {
  const GuaCalculator({
    required this.wheelSegments,
    required this.segmentsMap,
    required this.guaMap,
    required this.guaCi,
    required this.guaYaoData,
  });

  final Map<String, List<String>> wheelSegments;
  final Map<String, List<dynamic>> segmentsMap;
  final Map<String, String> guaMap;
  final Map<String, GuaCi> guaCi;
  final Map<String, List<String>> guaYaoData;

  /// [wheelAngles] 依序為六個轉盤的最終旋轉角度（單位：度，可正可負），
  /// 順序對應 [kYaoNames]：上爻、五爻、四爻、三爻、二爻、初爻。
  DivinationResult calculate(List<double> wheelAngles) {
    assert(wheelAngles.length == 6, 'wheelAngles 必須恰好有 6 個角度');

    final yaosRaw = <String>[
      for (var i = 0; i < 6; i++) _yaoAt(i, wheelAngles[i]),
    ];
    final yaosClean = yaosRaw.map(_stripMovingMark).toList(growable: false);

    final dongYaoIndexes = <int>[
      for (var i = 0; i < 6; i++)
        if (yaosRaw[i].contains('*')) i,
    ];

    final benGuaKey = _guaKeyFor(yaosClean);
    final benGuaName = guaMap[benGuaKey];

    String? zhiGuaKey;
    String? zhiGuaName;
    if (dongYaoIndexes.isNotEmpty) {
      final zhiYaosClean = List<String>.of(yaosClean);
      for (final index in dongYaoIndexes) {
        zhiYaosClean[index] = _flipYinYang(zhiYaosClean[index]);
      }
      zhiGuaKey = _guaKeyFor(zhiYaosClean);
      zhiGuaName = guaMap[zhiGuaKey];
    }

    final interpretation = _interpret(
      dongYaoIndexes: dongYaoIndexes,
      benGuaKey: benGuaKey,
      zhiGuaKey: zhiGuaKey,
    );

    return DivinationResult(
      benGuaKey: benGuaKey,
      benGuaName: benGuaName,
      zhiGuaKey: zhiGuaKey,
      zhiGuaName: zhiGuaName,
      dongYaoIndexes: dongYaoIndexes,
      yaosRaw: yaosRaw,
      yaosClean: yaosClean,
      interpretation: interpretation.description,
      judgementYaoText: interpretation.yaoText,
      judgementExplain: interpretation.explain,
    );
  }

  String _yaoAt(int wheelIndex, double angle) {
    final segmentIndex = angleToSegmentIndex(angle);
    final segments = wheelSegments[kWheelSegmentKeys[wheelIndex]]!;
    return segments[segmentIndex];
  }

  String _stripMovingMark(String yao) => yao.replaceAll('*', '');

  String _flipYinYang(String yao) => yao == '⚊' ? '⚋' : '⚊';

  /// 依 [key]（如 "14"，上卦索引+下卦索引各一碼）取得對應的
  /// [上卦符號, 下卦符號]，供畫面顯示卦象用。
  List<String> trigramSymbolsForKey(String key) {
    final upIndex = int.parse(key[0]);
    final downIndex = int.parse(key.substring(1));
    return [_symbolForTrigramIndex(upIndex), _symbolForTrigramIndex(downIndex)];
  }

  String _symbolForTrigramIndex(int index) {
    for (final entry in segmentsMap.values) {
      if (entry[1] == index) return entry[0] as String;
    }
    throw StateError('找不到索引 $index 對應的卦符號');
  }

  String _guaKeyFor(List<String> yaosClean) {
    final upGua = _binaryOf(yaosClean.sublist(0, 3));
    final downGua = _binaryOf(yaosClean.sublist(3, 6));
    final upIndex = segmentsMap[upGua]![1];
    final downIndex = segmentsMap[downGua]![1];
    return '$upIndex$downIndex';
  }

  String _binaryOf(List<String> yaos) {
    return yaos.map((yao) => yao == '⚊' ? '1' : '0').join();
  }

  _Interpretation _interpret({
    required List<int> dongYaoIndexes,
    required String benGuaKey,
    required String? zhiGuaKey,
  }) {
    switch (dongYaoIndexes.length) {
      case 0:
        return _Interpretation(
          description: '無動爻，以本卦卦辭占',
          yaoText: null,
          explain: guaCi[benGuaKey]?.ci ?? '',
        );
      case 1:
        final index = judgementYaoIndexFor(dongYaoIndexes)!;
        final yaoName = kYaoNames[index];
        return _Interpretation(
          description: '一爻變，本卦 $yaoName 爻辭占',
          yaoText: yaoName,
          explain: guaYaoData[benGuaKey]?[index] ?? '',
        );
      case 2:
        final index = judgementYaoIndexFor(dongYaoIndexes)!;
        final yaoName = kYaoNames[index];
        return _Interpretation(
          description: '二爻變，本卦上變爻($yaoName)爻辭占',
          yaoText: yaoName,
          explain: guaYaoData[benGuaKey]?[index] ?? '',
        );
      case 3:
        final benCi = guaCi[benGuaKey]?.ci ?? '';
        final zhiCi = zhiGuaKey == null ? '' : (guaCi[zhiGuaKey]?.ci ?? '');
        return _Interpretation(
          description: '三爻變，本卦之卦卦辭合占',
          yaoText: null,
          explain: '本卦：$benCi\n之卦：$zhiCi',
        );
      case 4:
        final index = judgementYaoIndexFor(dongYaoIndexes)!;
        final yaoName = kYaoNames[index];
        return _Interpretation(
          description: '四爻變，之卦下不變爻($yaoName)爻辭占',
          yaoText: yaoName,
          explain: zhiGuaKey == null
              ? ''
              : (guaYaoData[zhiGuaKey]?[index] ?? ''),
        );
      case 5:
        final index = judgementYaoIndexFor(dongYaoIndexes)!;
        final yaoName = kYaoNames[index];
        return _Interpretation(
          description: '五爻變，之卦不變爻($yaoName)爻辭占',
          yaoText: yaoName,
          explain: zhiGuaKey == null
              ? ''
              : (guaYaoData[zhiGuaKey]?[index] ?? ''),
        );
      case 6:
        return _Interpretation(
          description: '六爻變，以之卦卦辭占',
          yaoText: null,
          explain: zhiGuaKey == null ? '' : (guaCi[zhiGuaKey]?.ci ?? ''),
        );
      default:
        throw StateError('動爻數量不合法：${dongYaoIndexes.length}');
    }
  }
}

class _Interpretation {
  const _Interpretation({
    required this.description,
    required this.yaoText,
    required this.explain,
  });

  final String description;
  final String? yaoText;
  final String explain;
}
