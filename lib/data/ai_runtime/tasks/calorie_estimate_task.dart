import 'dart:convert';
import 'dart:typed_data';

import '../ai_result.dart';
import '../engine/ai_task.dart';
import '../engine/on_device_inference_engine.dart';
import '../hybrid_ai_runner.dart';

/// Task 2 — ước tính calo cho danh sách món ĐÃ có tên (on-device-ai-runtime.md
/// §6.2, §6.5.4). Không phải luồng LLM đa phương thức của meal-log #82.
class RecognizedFoodItem {
  const RecognizedFoodItem({
    required this.name,
    this.confidence,
    this.quantity,
    this.unit,
    this.expiryEstimate,
  });

  final String name;
  final double? confidence;
  final double? quantity;
  final String? unit;
  final DateTime? expiryEstimate;
}

class CalorieEstimateItem {
  const CalorieEstimateItem({required this.name, required this.kcal, this.confidence});
  final String name;
  final double kcal;

  /// `0` = không tra được / không quy đổi được — món vẫn nằm trong danh sách.
  final double? confidence;
}

class CalorieEstimateResult {
  const CalorieEstimateResult({
    required this.totalKcal,
    required this.items,
    required this.estimationMethod,
  });

  static const String lookupTable = 'lookup_table';
  static const String regressionModel = 'regression_model';
  static const String llm = 'llm';

  final double totalKcal;
  final List<CalorieEstimateItem> items;

  /// [lookupTable] | [regressionModel] | [llm].
  final String estimationMethod;
}

class CalorieEstimateInput implements InferenceInput {
  const CalorieEstimateInput(this.items);
  final List<RecognizedFoodItem> items;
}

class CalorieEstimateOutput implements InferenceOutput {
  const CalorieEstimateOutput(this.result, {this.confidence});
  final CalorieEstimateResult result;

  /// Tỉ lệ món tính được; `null` khi danh sách rỗng.
  @override
  final double? confidence;
}

class NutritionEntry {
  const NutritionEntry({required this.kcalPer100g, this.gramsPerUnit});
  final double kcalPer100g;
  final double? gramsPerUnit;
}

/// `nutrition_table.json` (§6.5.4) — ném [FormatException] khi sai schema.
class NutritionTable {
  NutritionTable._(this._entries);

  final Map<String, NutritionEntry> _entries;

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _combiningMarks = RegExp('[\u0300-\u036F]');

  /// trim + gộp khoảng trắng + chữ thường; GIỮ dấu.
  static String normalize(String name) =>
      name.trim().replaceAll(_spaces, ' ').toLowerCase();

  factory NutritionTable.fromJson(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('nutrition table must be an object');
    }
    final version = json['version'];
    if (version is! int || version != 1) {
      throw const FormatException('version must be int 1');
    }
    final entries = json['entries'];
    if (entries is! List || entries.isEmpty) {
      throw const FormatException('entries must be a non-empty list');
    }
    final byKey = <String, NutritionEntry>{};
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('entry must be an object');
      }
      final name = raw['name'];
      final aliases = raw['aliases'];
      final kcal = raw['kcalPer100g'];
      final grams = raw['gramsPerUnit'];
      if (name is! String || normalize(name).isEmpty) {
        throw const FormatException('name must be a non-empty string');
      }
      if (aliases is! List || aliases.any((a) => a is! String)) {
        throw FormatException('aliases of $name must be a string list');
      }
      if (kcal is! num || !kcal.isFinite || kcal < 0) {
        throw FormatException('kcalPer100g of $name must be finite >= 0');
      }
      if (grams != null && (grams is! num || !grams.isFinite || grams <= 0)) {
        throw FormatException('gramsPerUnit of $name must be null or > 0');
      }
      final entry = NutritionEntry(
        kcalPer100g: kcal.toDouble(),
        gramsPerUnit: (grams as num?)?.toDouble(),
      );
      final keys = <String>{
        normalize(name),
        for (final a in aliases.cast<String>()) normalize(a),
      }..remove('');
      for (final key in keys) {
        if (_combiningMarks.hasMatch(key)) {
          throw FormatException('"$key" uses combining marks — use NFC');
        }
        if (byKey.containsKey(key)) {
          throw FormatException('duplicate key "$key"');
        }
        byKey[key] = entry;
      }
    }
    return NutritionTable._(byKey);
  }

  NutritionEntry? lookup(String name) => _entries[normalize(name)];
}

/// Tra bảng thuần Dart — không cần model NN (§6.2, §6.5.4). Tên không khớp
/// CHÍNH XÁC → kcal 0, confidence 0, KHÔNG fuzzy (số calo sai nguy hiểm hơn
/// "không có dữ liệu").
class CalorieLookupEngine {
  const CalorieLookupEngine(this._table);

  final NutritionTable _table;

  static const double _defaultPortionGrams = 100;

  CalorieEstimateOutput estimate(List<RecognizedFoodItem> items) {
    final results = <CalorieEstimateItem>[];
    var computed = 0;
    for (final item in items) {
      final estimate = _estimate(item);
      if (estimate != null) computed++;
      results.add(CalorieEstimateItem(
        name: item.name,
        kcal: estimate?.$1 ?? 0,
        confidence: estimate?.$2 ?? 0,
      ));
    }
    return CalorieEstimateOutput(
      CalorieEstimateResult(
        totalKcal: results.fold<double>(0, (sum, i) => sum + i.kcal),
        items: results,
        estimationMethod: CalorieEstimateResult.lookupTable,
      ),
      confidence: items.isEmpty ? null : computed / items.length,
    );
  }

  /// (kcal, confidence) hoặc `null` khi không tra/không quy đổi được.
  (double, double)? _estimate(RecognizedFoodItem item) {
    final entry = _table.lookup(item.name);
    if (entry == null) return null;
    final grams = _grams(item, entry);
    if (grams == null) return null;
    return (entry.kcalPer100g * grams.$1 / 100, grams.$2);
  }

  /// (gram, confidence) theo bảng quy đổi §6.5.4.
  static (double, double)? _grams(RecognizedFoodItem item, NutritionEntry entry) {
    final q = item.quantity;
    final unit = item.unit?.trim().toLowerCase();
    if (q == null) {
      if (unit != null && unit.isNotEmpty) return null;
      return (entry.gramsPerUnit ?? _defaultPortionGrams, 0.5);
    }
    if (!q.isFinite || q < 0) return null;
    switch (unit) {
      case 'g':
        return (q, 1.0);
      case 'kg':
        return (q * 1000, 1.0);
      case 'ml':
        return (q, 0.8); // giả định khối lượng riêng = 1
      case 'l':
        return (q * 1000, 0.8);
      case null || '' || 'quả' || 'cái':
        final perUnit = entry.gramsPerUnit;
        return perUnit == null ? null : (q * perUnit, 1.0);
      default:
        return null;
    }
  }
}

abstract class CalorieEstimateRepository {
  /// [cloud] `null` → chạy cục bộ (BE chưa có endpoint cho bài toán này).
  Future<AIResult<CalorieEstimateResult>> estimate(
    List<RecognizedFoodItem> items, {
    Future<CalorieEstimateResult> Function()? cloud,
  });
}

class CalorieEstimateRepositoryImpl implements CalorieEstimateRepository {
  CalorieEstimateRepositoryImpl(this._runner);

  final HybridAIRunner _runner;

  @override
  Future<AIResult<CalorieEstimateResult>> estimate(
    List<RecognizedFoodItem> items, {
    Future<CalorieEstimateResult> Function()? cloud,
  }) =>
      _runner.run<CalorieEstimateResult>(
        task: AITask.calorieEstimate,
        cloud: cloud,
        cloudModelUsed: 'cloud:calorie-estimate',
        input: CalorieEstimateInput(items),
        fromOutput: (o) => (o as CalorieEstimateOutput).result,
      );
}
