import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 一筆占卜歷史紀錄，對應 PRD 第 4.3 節。
///
/// [dongYaoIndexes]、[yaosRaw] 存進 sqlite 前用 [jsonEncode] 轉成字串，
/// 讀出時用 [jsonDecode] 還原，詳見 [toMap]／[fromMap]。
@immutable
class DivinationRecord {
  const DivinationRecord({
    required this.id,
    required this.createdAt,
    required this.benGuaKey,
    required this.benGuaName,
    this.zhiGuaKey,
    this.zhiGuaName,
    required this.dongYaoIndexes,
    required this.yaosRaw,
    required this.interpretation,
    required this.judgementText,
    required this.explanation,
    this.note,
  });

  factory DivinationRecord.fromMap(Map<String, Object?> map) {
    return DivinationRecord(
      id: map['id']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
      benGuaKey: map['ben_gua_key']! as String,
      benGuaName: map['ben_gua_name']! as String,
      zhiGuaKey: map['zhi_gua_key'] as String?,
      zhiGuaName: map['zhi_gua_name'] as String?,
      dongYaoIndexes:
          (jsonDecode(map['dong_yao_indexes']! as String) as List<dynamic>)
              .cast<int>(),
      yaosRaw: (jsonDecode(map['yaos_raw']! as String) as List<dynamic>)
          .cast<String>(),
      interpretation: map['interpretation']! as String,
      judgementText: map['judgement_text']! as String,
      explanation: map['explanation']! as String,
      note: map['note'] as String?,
    );
  }

  /// uuid。
  final String id;

  final DateTime createdAt;

  /// 本卦代碼與顯示名稱。
  final String benGuaKey;
  final String benGuaName;

  /// 之卦代碼與顯示名稱；無動爻時為 null。
  final String? zhiGuaKey;
  final String? zhiGuaName;

  /// 動爻索引（0=上爻...5=初爻）。
  final List<int> dongYaoIndexes;

  /// 六爻原始符號（含 "*" 動爻標記）。
  final List<String> yaosRaw;

  /// 占法描述文字，例如「一爻變，本卦 上爻 爻辭占」。
  final String interpretation;

  /// 吉凶判斷內容。
  final String judgementText;

  /// 卦辭／爻辭的白話解釋。
  final String explanation;

  /// 使用者自行輸入的備註；可為 null。
  final String? note;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'ben_gua_key': benGuaKey,
      'ben_gua_name': benGuaName,
      'zhi_gua_key': zhiGuaKey,
      'zhi_gua_name': zhiGuaName,
      'dong_yao_indexes': jsonEncode(dongYaoIndexes),
      'yaos_raw': jsonEncode(yaosRaw),
      'interpretation': interpretation,
      'judgement_text': judgementText,
      'explanation': explanation,
      'note': note,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DivinationRecord &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.benGuaKey == benGuaKey &&
        other.benGuaName == benGuaName &&
        other.zhiGuaKey == zhiGuaKey &&
        other.zhiGuaName == zhiGuaName &&
        listEquals(other.dongYaoIndexes, dongYaoIndexes) &&
        listEquals(other.yaosRaw, yaosRaw) &&
        other.interpretation == interpretation &&
        other.judgementText == judgementText &&
        other.explanation == explanation &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    benGuaKey,
    benGuaName,
    zhiGuaKey,
    zhiGuaName,
    Object.hashAll(dongYaoIndexes),
    Object.hashAll(yaosRaw),
    interpretation,
    judgementText,
    explanation,
    note,
  );
}
