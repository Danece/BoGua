import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gua_ci.dart';
import '../models/yao_explain.dart';

/// 讀取 assets/data/ 底下的 64 卦靜態資料（JSON）並解析成型別化的記憶體結構。
///
/// 呼叫 [loadAll] 一次讀取全部 6 個檔案並快取結果；之後透過 [guaCi]、
/// [guaYaoData] 等 getter 存取都是直接讀快取，不會重複觸發 I/O。
class GuaDataSource {
  static const String _guaCiPath = 'assets/data/gua_ci.json';
  static const String _guaYaoDataPath = 'assets/data/gua_yao_data.json';
  static const String _guaMapPath = 'assets/data/gua_map.json';
  static const String _yaoExplainGeneralPath =
      'assets/data/yao_explain_general.json';
  static const String _segmentsMapPath = 'assets/data/segments_map.json';
  static const String _wheelSegmentsPath = 'assets/data/wheel_segments.json';

  Map<String, GuaCi>? _guaCi;
  Map<String, List<String>>? _guaYaoData;
  Map<String, String>? _guaMap;
  Map<String, YaoExplain>? _yaoExplainGeneral;
  Map<String, List<dynamic>>? _segmentsMap;
  Map<String, List<String>>? _wheelSegments;

  /// 是否已經呼叫過 [loadAll] 並完成快取。
  bool get isLoaded => _guaCi != null;

  /// 64 卦代碼（如 "10"）→ 卦辭與解釋。
  Map<String, GuaCi> get guaCi => _requireLoaded(_guaCi);

  /// 64 卦代碼 → 六爻爻辭，索引 0 = 上爻 ... 5 = 初爻。
  Map<String, List<String>> get guaYaoData => _requireLoaded(_guaYaoData);

  /// 64 卦代碼 → 顯示名稱（含卦象符號），例如 "䷪ 夬卦-澤天夬"。
  Map<String, String> get guaMap => _requireLoaded(_guaMap);

  /// 爻位（"上爻" ~ "初爻"）→ 通用階段解釋。
  Map<String, YaoExplain> get yaoExplainGeneral =>
      _requireLoaded(_yaoExplainGeneral);

  /// 三位元二進位字串 → [符號字串, 索引數字]。
  Map<String, List<dynamic>> get segmentsMap => _requireLoaded(_segmentsMap);

  /// segments_up/segments_five/.../segments_first → 六個轉盤區段字串。
  Map<String, List<String>> get wheelSegments =>
      _requireLoaded(_wheelSegments);

  T _requireLoaded<T>(T? value) {
    if (value == null) {
      throw StateError('GuaDataSource.loadAll() 尚未呼叫，資料尚未載入');
    }
    return value;
  }

  /// 一次讀取全部 6 個 JSON 檔並快取；重複呼叫不會重新讀取。
  Future<void> loadAll() async {
    if (isLoaded) return;

    final rawJsons = await Future.wait([
      _loadJsonMap(_guaCiPath),
      _loadJsonMap(_guaYaoDataPath),
      _loadJsonMap(_guaMapPath),
      _loadJsonMap(_yaoExplainGeneralPath),
      _loadJsonMap(_segmentsMapPath),
      _loadJsonMap(_wheelSegmentsPath),
    ]);

    final guaCiJson = rawJsons[0];
    final guaYaoDataJson = rawJsons[1];
    final guaMapJson = rawJsons[2];
    final yaoExplainJson = rawJsons[3];
    final segmentsMapJson = rawJsons[4];
    final wheelSegmentsJson = rawJsons[5];

    _guaCi = guaCiJson.map(
      (key, value) =>
          MapEntry(key, GuaCi.fromJson(value as Map<String, dynamic>)),
    );

    _guaYaoData = guaYaoDataJson.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
    );

    _guaMap = guaMapJson.map((key, value) => MapEntry(key, value as String));

    _yaoExplainGeneral = yaoExplainJson.map(
      (key, value) =>
          MapEntry(key, YaoExplain.fromJson(value as Map<String, dynamic>)),
    );

    _segmentsMap = segmentsMapJson.map(
      (key, value) => MapEntry(key, value as List<dynamic>),
    );

    _wheelSegments = wheelSegmentsJson.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
    );
  }

  Future<Map<String, dynamic>> _loadJsonMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

/// 提供一份已完成 [GuaDataSource.loadAll] 的 [GuaDataSource]，供畫面直接讀取。
final guaDataSourceProvider = FutureProvider<GuaDataSource>((ref) async {
  final dataSource = GuaDataSource();
  await dataSource.loadAll();
  return dataSource;
});
