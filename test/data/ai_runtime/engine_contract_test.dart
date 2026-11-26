import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/ai_task.dart';

/// Hợp đồng seam on-device inference — issue #116, on-device-ai-runtime.md §4.1.
void main() {
  group('AITask', () {
    test('đúng 4 giá trị — không thiếu, không thừa', () {
      expect(AITask.values, hasLength(4));
      expect(AITask.values.toSet(), {
        AITask.receiptOcr,
        AITask.calorieEstimate,
        AITask.repetitionScore,
        AITask.ruleBasedSelection,
      });
    });
  });

  group('Guard import runtime NN (§4.1, Guard #2)', () {
    // Runtime chỉ được chốt sau benchmark thiết bị thật — ngoài `engine/`
    // không file nào được phụ thuộc trực tiếp plugin runtime cụ thể.
    const engineDir = 'lib/data/ai_runtime/engine/';
    final runtimeImport = RegExp(
      r'''^\s*(import|export)\s+['"]package:(tflite_flutter|onnxruntime|onnxruntime_flutter|google_mlkit_text_recognition)/''',
      multiLine: true,
    );

    List<String> offenders(Directory root) {
      final hits = <String>[];
      for (final f in root.listSync(recursive: true).whereType<File>()) {
        final path = f.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart') || path.contains(engineDir)) continue;
        if (runtimeImport.hasMatch(f.readAsStringSync())) hits.add(path);
      }
      return hits;
    }

    test('không file nào ngoài engine/ import tflite/onnx/ML Kit', () {
      expect(offenders(Directory('lib')), isEmpty);
    });

    test('regex bắt đúng import runtime và bỏ qua import thường', () {
      final tmp = Directory.systemTemp.createTempSync('guard_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/bad.dart').writeAsStringSync(
          "import 'package:tflite_flutter/tflite_flutter.dart';\n");
      File('${tmp.path}/ok.dart').writeAsStringSync(
          "import 'package:flutter/material.dart';\n"
          "// import 'package:onnxruntime/onnxruntime.dart';\n");

      final hits = offenders(tmp);
      expect(hits, hasLength(1));
      expect(hits.single, endsWith('bad.dart'));
    });
  });
}
