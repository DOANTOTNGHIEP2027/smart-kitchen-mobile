import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_version.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/ai_task.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/model_manifest.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/model_registry.dart';
import 'package:smart_kitchen_mobile/utils/sha256.dart';

/// Hợp đồng đóng gói model on-device — issue #117, on-device-ai-runtime.md §5.4.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const rulesJson = '{"weights":{"expiringPriority":0.4,"repetitionPenalty":0.5}}';
  const nutritionJson = '{"rice":130}';
  final tflite = Uint8List.fromList(<int>[0x54, 0x46, 0x4c, 0x33, 1, 2, 3]);

  String dir(AITask t) => 'assets/models/${t.assetDir}/v1';

  /// Fixture giả nằm ở `v1` — `defaultVersions[repetitionScore]` đã lên 2
  /// (#120, §6.6.8) nên mọi registry trên fixture giả ghim version 1.
  const fixtureVersions = <AITask, int>{
    AITask.receiptOcr: 1,
    AITask.calorieEstimate: 1,
    AITask.repetitionScore: 1,
    AITask.ruleBasedSelection: 1,
  };

  Map<String, dynamic> meta(AITask task, Map<String, dynamic> overrides) {
    final base = <String, dynamic>{
      'task': task.assetDir,
      'modelVersion': 1,
      'appMinVersion': '0.1.0',
      'runtime': 'rules-only',
      'payloadFile': null,
      'checksumSha256': null,
      'inputShape': null,
      'inputDType': null,
      'preprocessing': null,
      'outputShape': null,
      'outputType': ModelManifest.outputTypes[task],
      'labelMapFile': null,
      'quantization': 'n/a',
    }..addAll(overrides);
    return base;
  }

  Map<String, dynamic> withMlkitChecksum(Map<String, dynamic> m) =>
      m..['checksumSha256'] = sha256Hex(ModelManifest.canonicalManifestJson(m));

  /// Bộ asset giả đủ 4 task HỢP LỆ, payload đã ship (AC "cả 4 true").
  Map<String, List<int>> fullPackages() {
    final ocr = withMlkitChecksum(meta(AITask.receiptOcr, <String, dynamic>{
      'runtime': 'mlkit-bundled',
      'inputShape': <int>[1, -1, -1, 3],
      'inputDType': 'uint8',
      'preprocessing': <String, String>{'resize': 'auto', 'normalize': 'none', 'colorOrder': 'RGB'},
    }));
    return <String, List<int>>{
      '${dir(AITask.receiptOcr)}/metadata.json': utf8.encode(jsonEncode(ocr)),
      '${dir(AITask.calorieEstimate)}/metadata.json': utf8.encode(jsonEncode(meta(AITask.calorieEstimate, <String, dynamic>{
        'payloadFile': 'nutrition_table.json',
        'checksumSha256': sha256Hex(utf8.encode(nutritionJson)),
      }))),
      '${dir(AITask.calorieEstimate)}/nutrition_table.json': utf8.encode(nutritionJson),
      '${dir(AITask.repetitionScore)}/metadata.json': utf8.encode(jsonEncode(meta(AITask.repetitionScore, <String, dynamic>{
        'runtime': 'tflite',
        'payloadFile': 'model.tflite',
        'checksumSha256': sha256Hex(tflite),
        'inputShape': <int>[1, 14],
        'inputDType': 'float32',
        'outputShape': <int>[1, 1],
        'quantization': 'int8',
        'labelMapFile': 'labels.txt',
      }))),
      '${dir(AITask.repetitionScore)}/model.tflite': tflite,
      '${dir(AITask.repetitionScore)}/labels.txt': utf8.encode('score\n'),
      '${dir(AITask.ruleBasedSelection)}/metadata.json': utf8.encode(jsonEncode(meta(AITask.ruleBasedSelection, <String, dynamic>{
        'payloadFile': 'rules_config.json',
        'checksumSha256': sha256Hex(utf8.encode(rulesJson)),
      }))),
      '${dir(AITask.ruleBasedSelection)}/rules_config.json': utf8.encode(rulesJson),
    };
  }

  AssetBytesLoader loader(Map<String, List<int>> files) => (path) async {
        final v = files[path];
        if (v == null) throw FlutterError('asset not found: $path');
        return ByteData.sublistView(Uint8List.fromList(v));
      };

  Future<ModelRegistry> boot(Map<String, List<int>> files, {String app = '0.1.0'}) async {
    final reg = ModelRegistry(appVersion: app, modelVersions: fixtureVersions, loader: loader(files));
    await reg.bootstrap();
    return reg;
  }

  void patchMeta(Map<String, List<int>> files, AITask task, void Function(Map<String, dynamic>) edit) {
    final path = '${dir(task)}/metadata.json';
    final m = jsonDecode(utf8.decode(files[path]!)) as Map<String, dynamic>;
    edit(m);
    files[path] = utf8.encode(jsonEncode(m));
  }

  group('ModelManifest.fromJson (§5.4.1)', () {
    test('đủ field — tflite đã ship', () {
      final m = ModelManifest.fromJson(AITask.repetitionScore, meta(AITask.repetitionScore, <String, dynamic>{
        'runtime': 'tflite',
        'payloadFile': 'model.tflite',
        'checksumSha256': 'AB' * 32,
        'inputShape': <int>[1, -1],
        'inputDType': 'float32',
        'outputShape': <int>[1, 1],
        'preprocessing': <String, String>{'normalize': 'zscore'},
        'labelMapFile': 'labels.txt',
        'quantization': 'int8',
      }));
      expect(m.modelVersion, 1);
      expect(m.appMinVersion, '0.1.0');
      expect(m.checksumSha256, 'ab' * 32, reason: 'chuẩn hoá chữ thường');
      expect(m.inputShape, <int>[1, -1]);
      expect(m.outputShape, <int>[1, 1]);
      expect(m.inputDType, 'float32');
      expect(m.preprocessing, <String, String>{'normalize': 'zscore'});
      expect(m.labelMapFile, 'labels.txt');
      expect(m.quantization, 'int8');
      expect(m.outputType, 'repetition_scores');
      expect(m.payloadShipped, isTrue);
      expect(m.modelUsed, 'on-device:repetition_score@v1');
    });

    test('mlkit-bundled: shape null hợp lệ, không payload, bắt buộc checksum', () {
      final m = ModelManifest.fromJson(AITask.receiptOcr,
          meta(AITask.receiptOcr, <String, dynamic>{'runtime': 'mlkit-bundled', 'checksumSha256': '0' * 64}));
      expect(m.isMlkitBundled, isTrue);
      expect(m.inputShape, isNull);
      expect(m.outputShape, isNull);
      expect(m.payloadShipped, isFalse);
    });

    test('payload chưa ship (checksum null) → hợp lệ, payloadShipped = false; shape được null', () {
      final m = ModelManifest.fromJson(AITask.repetitionScore,
          meta(AITask.repetitionScore, <String, dynamic>{'runtime': 'tflite', 'payloadFile': 'model.tflite'}));
      expect(m.payloadShipped, isFalse);
    });

    test('field lạ bị bỏ qua', () {
      ModelManifest.fromJson(AITask.calorieEstimate,
          meta(AITask.calorieEstimate, <String, dynamic>{'payloadFile': 'nutrition_table.json', 'futureField': 'x'}));
    });

    final invalid = <String, (AITask, Map<String, dynamic>)>{
      'thiếu field (labelMapFile)': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json'})..remove('labelMapFile')),
      'task lệch thư mục': (AITask.calorieEstimate, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json'})),
      'modelVersion 0': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'modelVersion': 0})),
      'modelVersion là chuỗi': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'modelVersion': '1'})),
      'appMinVersion có pre-release': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'appMinVersion': '1.0.0-beta'})),
      'appMinVersion số 0 đứng đầu': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'appMinVersion': '01.0.0'})),
      'runtime lạ': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'runtime': 'tensorrt'})),
      'rules-only thiếu payloadFile': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{})),
      'mlkit-bundled có payloadFile': (AITask.receiptOcr, meta(AITask.receiptOcr, <String, dynamic>{'runtime': 'mlkit-bundled', 'payloadFile': 'm.tflite', 'checksumSha256': '0' * 64})),
      'mlkit-bundled thiếu checksum': (AITask.receiptOcr, meta(AITask.receiptOcr, <String, dynamic>{'runtime': 'mlkit-bundled'})),
      'checksum sai định dạng': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'checksumSha256': 'deadbeef'})),
      'tflite đã ship thiếu shape': (AITask.repetitionScore, meta(AITask.repetitionScore, <String, dynamic>{'runtime': 'tflite', 'payloadFile': 'm.tflite', 'checksumSha256': '0' * 64})),
      'shape có chiều 0': (AITask.repetitionScore, meta(AITask.repetitionScore, <String, dynamic>{'runtime': 'tflite', 'payloadFile': 'm.tflite', 'inputShape': <int>[1, 0]})),
      'shape rỗng': (AITask.repetitionScore, meta(AITask.repetitionScore, <String, dynamic>{'runtime': 'tflite', 'payloadFile': 'm.tflite', 'outputShape': <int>[]})),
      'outputType sai task': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'outputType': 'kcal_estimate'})),
      'rules-only nhưng quantization int8 (M1)': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'quantization': 'int8'})),
      'tflite đã ship nhưng quantization n/a (M1)': (AITask.repetitionScore, meta(AITask.repetitionScore, <String, dynamic>{'runtime': 'tflite', 'payloadFile': 'm.tflite', 'checksumSha256': '0' * 64, 'inputShape': <int>[1], 'outputShape': <int>[1], 'inputDType': 'float32'})),
      'quantization lạ': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'quantization': 'int4'})),
      'payloadFile path traversal': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': '../secret.json'})),
      'payloadFile có ".."': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'a..json'})),
      'payloadFile = metadata.json': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'metadata.json'})),
      'labelMapFile có "/"': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'labelMapFile': 'x/labels.txt'})),
      'preprocessing giá trị không phải chuỗi': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'preprocessing': <String, dynamic>{'resize': 224}})),
      'có số thực': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'extra': 1.5})),
      'chuỗi không phải ASCII': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'note': 'món ăn'})),
      'số nguyên ngoài ±2^53': (AITask.ruleBasedSelection, meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json', 'big': 9007199254740993})),
    };
    for (final entry in invalid.entries) {
      test('sai: ${entry.key} → FormatException', () {
        final (task, json) = entry.value;
        expect(() => ModelManifest.fromJson(task, json), throwsFormatException);
      });
    }
  });

  group('canonicalManifestJson (§5.4.2)', () {
    test('hash cố định khớp Python json.dumps(sort_keys, separators, ensure_ascii=False)', () {
      final m = meta(AITask.receiptOcr, <String, dynamic>{
        'runtime': 'mlkit-bundled',
        'checksumSha256': 'bỏ qua',
        'inputShape': <int>[1, -1, -1, 3],
        'inputDType': 'uint8',
        'preprocessing': <String, String>{'resize': 'auto', 'normalize': 'none', 'colorOrder': 'RGB'},
      });
      expect(
        utf8.decode(ModelManifest.canonicalManifestJson(m)),
        '{"appMinVersion":"0.1.0","inputDType":"uint8","inputShape":[1,-1,-1,3],"labelMapFile":null,'
        '"modelVersion":1,"outputShape":null,"outputType":"ocr_text_lines","payloadFile":null,'
        '"preprocessing":{"colorOrder":"RGB","normalize":"none","resize":"auto"},"quantization":"n/a",'
        '"runtime":"mlkit-bundled","task":"receipt_ocr"}',
      );
      // Giá trị sinh bằng tool/model_manifest_checksum.py.
      expect(sha256Hex(ModelManifest.canonicalManifestJson(m)),
          '56663620c95b8430b5828c33fc87c30c3c47a6b79488375f99e1c923f312ae0f');
    });

    test('chỉ bỏ checksumSha256 ở cấp gốc; thứ tự key / khoảng trắng không đổi hash', () {
      final a = <String, dynamic>{'b': 1, 'a': <String, dynamic>{'checksumSha256': 'x', 'z': null}, 'checksumSha256': 'y'};
      final b = jsonDecode('{ "checksumSha256": "other",\r\n "a": {"z": null, "checksumSha256": "x"}, "b": 1 }')
          as Map<String, dynamic>;
      expect(utf8.decode(ModelManifest.canonicalManifestJson(a)), '{"a":{"checksumSha256":"x","z":null},"b":1}');
      expect(ModelManifest.canonicalManifestJson(b), ModelManifest.canonicalManifestJson(a));
    });
  });

  group('ModelRegistry (§5.4.2 thứ tự kiểm, Guard #7)', () {
    test('trước bootstrap: không task nào khả dụng, lý do notBootstrapped', () {
      final reg = ModelRegistry(appVersion: '0.1.0', modelVersions: fixtureVersions, loader: loader(fullPackages()));
      for (final t in AITask.values) {
        expect(reg.isAvailable(t), isFalse);
        expect(reg.unavailableReason(t), ModelUnavailableReason.notBootstrapped);
      }
    });

    test('đủ 4 package hợp lệ → cả 4 isAvailable == true', () async {
      final reg = await boot(fullPackages());
      for (final t in AITask.values) {
        expect(reg.isAvailable(t), isTrue, reason: t.name);
        expect(reg.unavailableReason(t), isNull);
        expect(reg.manifestFor(t).task, t);
      }
      expect(reg.payloadFor(AITask.receiptOcr), isNull, reason: 'mlkit-bundled không có payload');
      expect(reg.payloadFor(AITask.repetitionScore), tflite);
    });

    final breakers = <String, (ModelUnavailableReason, void Function(Map<String, List<int>>, AITask))>{
      'thiếu metadata.json': (ModelUnavailableReason.missing, (f, t) => f.remove('${dir(t)}/metadata.json')),
      'metadata không phải JSON': (ModelUnavailableReason.invalidManifest, (f, t) => f['${dir(t)}/metadata.json'] = utf8.encode('{oops')),
      'metadata là mảng JSON': (ModelUnavailableReason.invalidManifest, (f, t) => f['${dir(t)}/metadata.json'] = utf8.encode('[]')),
      'modelVersion lệch thư mục': (ModelUnavailableReason.invalidManifest, (f, t) => patchMeta(f, t, (m) => m['modelVersion'] = 2)),
      'appMinVersion > app': (ModelUnavailableReason.appTooOld, (f, t) => patchMeta(f, t, (m) {
            m['appMinVersion'] = '0.2.0';
            if (m['runtime'] == 'mlkit-bundled') withMlkitChecksum(m);
          })),
      'checksum lệch (đúng định dạng)': (ModelUnavailableReason.checksumMismatch, (f, t) => patchMeta(f, t, (m) => m['checksumSha256'] = 'de' * 32)),
    };

    for (final entry in breakers.entries) {
      test('${entry.key} ở TỪNG task → chỉ task đó false, đúng lý do, 3 task còn lại true', () async {
        final (reason, breakIt) = entry.value;
        for (final broken in AITask.values) {
          final files = fullPackages();
          breakIt(files, broken);
          final reg = await boot(files);
          for (final t in AITask.values) {
            if (t == broken) {
              expect(reg.isAvailable(t), isFalse, reason: '${t.name} hỏng');
              expect(reg.unavailableReason(t), reason, reason: t.name);
              expect(reg.payloadFor(t), isNull);
            } else {
              expect(reg.isAvailable(t), isTrue, reason: '${t.name} không bị ảnh hưởng');
            }
          }
        }
      });
    }

    test('thứ tự kiểm: appTooOld đứng TRƯỚC checksum mlkit (L1)', () async {
      final files = fullPackages();
      // Không tính lại checksum: cả 2 lỗi cùng có — phải báo appTooOld.
      patchMeta(files, AITask.receiptOcr, (m) => m['appMinVersion'] = '9.0.0');
      expect((await boot(files)).unavailableReason(AITask.receiptOcr), ModelUnavailableReason.appTooOld);
    });

    test('key map không phải String → FormatException, không TypeError (L2)', () {
      final json = meta(AITask.ruleBasedSelection, <String, dynamic>{'payloadFile': 'r.json'})
        ..['preprocessing'] = <Object, String>{1: 'x'};
      expect(() => ModelManifest.fromJson(AITask.ruleBasedSelection, json), throwsFormatException);
    });

    test('mlkit-bundled: sửa 1 field mà không tính lại checksum → checksumMismatch', () async {
      final files = fullPackages();
      patchMeta(files, AITask.receiptOcr, (m) => m['inputDType'] = 'float32');
      final reg = await boot(files);
      expect(reg.unavailableReason(AITask.receiptOcr), ModelUnavailableReason.checksumMismatch);
    });

    test('payload chưa ship → payloadNotShipped, KHÔNG đọc file payload', () async {
      final files = fullPackages();
      patchMeta(files, AITask.calorieEstimate, (m) => m['checksumSha256'] = null);
      final read = <String>[];
      final base = loader(files);
      final reg = ModelRegistry(appVersion: '0.1.0', modelVersions: fixtureVersions, loader: (p) {
        read.add(p);
        return base(p);
      });
      await reg.bootstrap();
      expect(reg.unavailableReason(AITask.calorieEstimate), ModelUnavailableReason.payloadNotShipped);
      expect(read, isNot(contains('${dir(AITask.calorieEstimate)}/nutrition_table.json')));
    });

    test('payload / labelMap khai mà không có file → missing', () async {
      final noPayload = fullPackages()..remove('${dir(AITask.ruleBasedSelection)}/rules_config.json');
      expect((await boot(noPayload)).unavailableReason(AITask.ruleBasedSelection), ModelUnavailableReason.missing);
      final noLabels = fullPackages()..remove('${dir(AITask.repetitionScore)}/labels.txt');
      expect((await boot(noLabels)).unavailableReason(AITask.repetitionScore), ModelUnavailableReason.missing);
    });

    test('payload bị sửa 1 byte → checksumMismatch', () async {
      final files = fullPackages();
      files['${dir(AITask.repetitionScore)}/model.tflite'] = List<int>.of(tflite)..[3] ^= 0xff;
      expect((await boot(files)).unavailableReason(AITask.repetitionScore), ModelUnavailableReason.checksumMismatch);
    });

    test('app version sai định dạng → mọi task invalidManifest, bootstrap KHÔNG throw', () async {
      final reg = await boot(fullPackages(), app: '0.1');
      for (final t in AITask.values) {
        expect(reg.unavailableReason(t), ModelUnavailableReason.invalidManifest);
      }
    });

    test('appMinVersion so theo số, không theo chuỗi (0.10.0 > 0.9.0)', () async {
      final files = fullPackages();
      patchMeta(files, AITask.ruleBasedSelection, (m) => m['appMinVersion'] = '0.9.0');
      expect((await boot(files, app: '0.10.0')).isAvailable(AITask.ruleBasedSelection), isTrue);
      expect((await boot(files, app: '0.8.9')).unavailableReason(AITask.ruleBasedSelection),
          ModelUnavailableReason.appTooOld);
    });

    test('loader ném lỗi bất kỳ (không phải FlutterError) → không throw', () async {
      final reg = ModelRegistry(appVersion: '0.1.0', modelVersions: fixtureVersions, loader: (_) async => throw StateError('boom'));
      await reg.bootstrap();
      expect(reg.unavailableReason(AITask.ruleBasedSelection), ModelUnavailableReason.missing);
    });

    test('bootstrap lại sau khi sửa → trạng thái cập nhật (không giữ lý do cũ)', () async {
      final files = fullPackages()..remove('${dir(AITask.receiptOcr)}/metadata.json');
      final reg = ModelRegistry(appVersion: '0.1.0', modelVersions: fixtureVersions, loader: (p) => loader(files)(p));
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.receiptOcr), isFalse);
      files.addAll(fullPackages());
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.receiptOcr), isTrue);
      expect(reg.unavailableReason(AITask.receiptOcr), isNull);
    });
  });

  group('Asset THẬT đang ship (§5.4.4, §5.4.5)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('AppVersion.current khớp pubspec (không pre-release)', () {
      final match = RegExp(r'^version:\s*([^\s+]+)(\+\S+)?\s*$', multiLine: true).firstMatch(pubspec);
      expect(match, isNotNull);
      expect(match!.group(1), AppVersion.current);
      expect(RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$').hasMatch(AppVersion.current), isTrue);
    });

    test('mọi thư mục v<N>: khớp AITask, đủ metadata + CHANGELOG (## vN), version đúng, khai trong pubspec', () {
      final root = Directory('assets/models');
      final taskDirs = root.listSync().whereType<Directory>().map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last).toSet();
      expect(taskDirs, AITask.values.map((t) => t.assetDir).toSet());
      for (final task in AITask.values) {
        final versions = Directory('assets/models/${task.assetDir}').listSync().whereType<Directory>().toList();
        expect(versions, isNotEmpty, reason: task.assetDir);
        for (final v in versions) {
          final name = v.uri.pathSegments.where((s) => s.isNotEmpty).last;
          expect(RegExp(r'^v[1-9]\d*$').hasMatch(name), isTrue, reason: v.path);
          final n = int.parse(name.substring(1));
          final path = 'assets/models/${task.assetDir}/$name';
          final m = jsonDecode(File('$path/metadata.json').readAsStringSync()) as Map<String, dynamic>;
          final manifest = ModelManifest.fromJson(task, m);
          expect(manifest.modelVersion, n, reason: path);
          final changelog = File('$path/CHANGELOG.md');
          expect(changelog.existsSync(), isTrue, reason: '$path/CHANGELOG.md');
          expect(changelog.readAsStringSync(), contains('## $name'), reason: path);
          expect(RegExp(r'^\s+- ' + RegExp.escape(path) + r'/\s*$', multiLine: true).hasMatch(pubspec), isTrue,
              reason: '$path phải khai trong pubspec (không tính dòng comment)');
        }
        expect(ModelRegistry.defaultVersions[task],
            versions.map((v) => int.parse(v.uri.pathSegments.where((s) => s.isNotEmpty).last.substring(1))).reduce((a, b) => a > b ? a : b),
            reason: 'defaultVersions = version mới nhất của ${task.assetDir}');
        final current = jsonDecode(File('assets/models/${task.assetDir}/v${ModelRegistry.defaultVersions[task]}/metadata.json')
            .readAsStringSync()) as Map<String, dynamic>;
        final min = (current['appMinVersion'] as String).split('.').map(int.parse).toList();
        final app = AppVersion.current.split('.').map(int.parse).toList();
        expect(min[0] * 1000000 + min[1] * 1000 + min[2] <= app[0] * 1000000 + app[1] * 1000 + app[2], isTrue,
            reason: '${task.assetDir}: appMinVersion phải ≤ AppVersion.current');
      }
    });

    test('bootstrap qua rootBundle THẬT → đúng bảng §5.4.4', () async {
      final reg = ModelRegistry(appVersion: AppVersion.current);
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.receiptOcr), isTrue);
      expect(reg.isAvailable(AITask.ruleBasedSelection), isTrue);
      expect(reg.unavailableReason(AITask.calorieEstimate), ModelUnavailableReason.payloadNotShipped);
      // #120: v2 rules-only đã ship (§6.6.4).
      expect(reg.isAvailable(AITask.repetitionScore), isTrue);
      expect(reg.payloadFor(AITask.repetitionScore), isNotNull);
      expect(reg.manifestFor(AITask.repetitionScore).modelUsed, 'on-device:repetition_score@v2');
      expect(reg.payloadFor(AITask.ruleBasedSelection), isNotNull);
    });
  });
}
