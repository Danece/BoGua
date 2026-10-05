import 'package:flutter/foundation.dart';

/// 單一卦的卦辭與白話解釋。對應 assets/data/gua_ci.json 的每個項目。
@immutable
class GuaCi {
  const GuaCi({
    required this.name,
    required this.ci,
    required this.explain,
  });

  factory GuaCi.fromJson(Map<String, dynamic> json) {
    return GuaCi(
      name: json['name'] as String,
      ci: json['ci'] as String,
      explain: json['explain'] as String,
    );
  }

  /// 卦名，例如「夬」。
  final String name;

  /// 卦辭原文。
  final String ci;

  /// 白話解釋。
  final String explain;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuaCi &&
        other.name == name &&
        other.ci == ci &&
        other.explain == explain;
  }

  @override
  int get hashCode => Object.hash(name, ci, explain);
}
