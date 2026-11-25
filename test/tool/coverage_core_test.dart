import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/coverage_core_lib.dart';

/// #93 §10.2 — logic tóm tắt coverage core.
void main() {
  const sample = '''
SF:lib\\stores\\a_store.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:D:/proj/lib/widgets/b.dart
DA:1,1
DA:2,1
DA:3,1
end_of_record
SF:lib/scenes/x/widgets/c.dart
LF:5
LH:0
end_of_record
''';

  test('normalizePath: \\ → /, cắt về lib/..., bỏ project root', () {
    expect(
        normalizePath(r'lib\stores\a_store.dart'), 'lib/stores/a_store.dart');
    expect(
      normalizePath(r'D:\proj\lib\w.dart', projectRoot: r'D:\proj'),
      'lib/w.dart',
    );
    expect(normalizePath('/x/y/lib/w.dart'), 'lib/w.dart');
  });

  test('parseLcov: đọc LF/LH, dự phòng DA khi thiếu LF/LH', () {
    final lcov = parseLcov(sample);
    expect(lcov['lib/stores/a_store.dart']!.linesFound, 2);
    expect(lcov['lib/stores/a_store.dart']!.linesHit, 1);
    expect(lcov['lib/widgets/b.dart']!.linesFound, 3);
    expect(lcov['lib/widgets/b.dart']!.linesHit, 3);
  });

  test('classify + isCore theo glob §10.1', () {
    expect(classify('lib/stores/a_store.dart'), CoverageGroup.store);
    expect(
        classify('lib/scenes/shell/app_shell_store.dart'), CoverageGroup.store);
    expect(classify('lib/widgets/app_button.dart'), CoverageGroup.widget);
    expect(classify('lib/scenes/x/widgets/y/z.dart'), CoverageGroup.widget);
    expect(classify('lib/scenes/x/scenes/x_scene.dart'), CoverageGroup.scene);
    expect(classify('lib/data/x.dart'), CoverageGroup.other);
    expect(isCore('lib/stores/a_store.g.dart'), isFalse);
    expect(isCore('lib/demo/demo_store.dart'), isFalse);
    expect(isCore('lib/scenes/dev/widgets/w.dart'), isFalse);
    expect(isCore('lib/l10n/x_store.dart'), isFalse);
    expect(isCore('lib/widgets/app_button.dart'), isTrue);
  });

  test('summarizeGroup: % gộp = ΣLH/ΣLF (không trung bình %), phát hiện vắng',
      () {
    final lcov = parseLcov(sample);
    final s = summarizeGroup(<String>[
      'lib/stores/a_store.dart', // 1/2
      'lib/widgets/b.dart', // 3/3
      'lib/scenes/x/widgets/c.dart', // 0/5
      'lib/widgets/missing.dart',
    ], lcov);
    expect(s.linesFound, 10);
    expect(s.linesHit, 4);
    expect(s.percent, closeTo(40, 1e-9)); // trung bình % sẽ là 50 — sai
    expect(s.absent, <String>['lib/widgets/missing.dart']);
  });

  test('worstFiles: sắp theo LF − LH giảm dần', () {
    final lcov = parseLcov(sample);
    final worst = worstFiles(lcov.keys.toList(), lcov, count: 2);
    expect(worst.map((e) => e.key), <String>[
      'lib/scenes/x/widgets/c.dart',
      'lib/stores/a_store.dart',
    ]);
  });

  test('buildImportsFile: có ignore_for_file unused_import + prefix riêng', () {
    final content = buildImportsFile(
      <String>['lib/widgets/b.dart', 'lib/stores/a_store.dart'],
      'pkg',
    );
    expect(content, contains('// ignore_for_file: unused_import'));
    expect(
        content,
        contains(
            'ignore_for_file: no_leading_underscores_for_library_prefixes'));
    expect(content, contains('// GENERATED'));
    expect(
        content, contains("import 'package:pkg/stores/a_store.dart' as _i0;"));
    expect(content, contains("import 'package:pkg/widgets/b.dart' as _i1;"));
    expect(content, contains('void main()'));
  });
}
