import 'package:flutter/foundation.dart';

/// 某一爻位的通用階段解釋。對應 assets/data/yao_explain_general.json 的每個項目，
/// key 為「上爻」～「初爻」。
@immutable
class YaoExplain {
  const YaoExplain({
    required this.stage,
    required this.position,
    required this.meaning,
    required this.advice,
  });

  factory YaoExplain.fromJson(Map<String, dynamic> json) {
    return YaoExplain(
      stage: json['stage'] as String,
      position: json['position'] as String,
      meaning: json['meaning'] as String,
      advice: json['advice'] as String,
    );
  }

  /// 階段名稱，例如「巔峰期」。
  final String stage;

  /// 爻位描述，例如「尊位」。
  final String position;

  /// 這個階段的意涵。
  final String meaning;

  /// 建議。
  final String advice;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YaoExplain &&
        other.stage == stage &&
        other.position == position &&
        other.meaning == meaning &&
        other.advice == advice;
  }

  @override
  int get hashCode => Object.hash(stage, position, meaning, advice);
}
