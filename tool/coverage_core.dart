import 'dart:io';

import 'src/coverage_core_lib.dart';

/// Coverage "core" không thổi phồng % (#93 — app-performance-audit §10.2).
///
/// ```bash
/// flutter test --coverage
/// dart run tool/coverage_core.dart                  # đọc coverage/lcov.info
/// dart run tool/coverage_core.dart --lcov <file>    # đọc lcov khác
/// dart run tool/coverage_core.dart --write-imports  # sinh lại test import
/// ```
///
/// Core = `lib/**/*_store.dart` + `lib/widgets/**` + `lib/scenes/**/widgets/**`,
/// loại `*.g.dart`, `lib/l10n/**`, `lib/demo/**`, `lib/scenes/dev/**`.
/// % = ΣLH/ΣLF. File core vắng trong lcov → liệt kê "VẮNG MẶT", exit code 1.
void main(List<String> args) {
  final libFiles = _listLibFiles();
  final coreFiles = libFiles.where(isCore).toList()..sort();

  if (args.contains('--write-imports')) {
    final out = File('test/coverage_core_imports_test.dart');
    out.writeAsStringSync(buildImportsFile(coreFiles, _packageName()));
    // Format ngay để sinh lại không tạo diff do formatter.
    Process.runSync('dart', <String>['format', out.path], runInShell: true);
    stdout.writeln('Đã ghi ${out.path} (${coreFiles.length} file core).');
    return;
  }

  final lcovIdx = args.indexOf('--lcov');
  final lcovPath = lcovIdx >= 0 && lcovIdx + 1 < args.length
      ? args[lcovIdx + 1]
      : 'coverage/lcov.info';
  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    stderr
        .writeln('Không thấy $lcovPath — chạy flutter test --coverage trước.');
    exitCode = 2;
    return;
  }
  final lcov = parseLcov(
    lcovFile.readAsStringSync(),
    projectRoot: Directory.current.path,
  );

  List<String> group(CoverageGroup g) => libFiles
      .where((f) => !isExcluded(f) && classify(f) == g)
      .toList(growable: false);

  final stores = summarizeGroup(group(CoverageGroup.store), lcov);
  final widgets = summarizeGroup(group(CoverageGroup.widget), lcov);
  final core = summarizeGroup(coreFiles, lcov);
  final scenes = summarizeGroup(group(CoverageGroup.scene), lcov);
  final all = summarizeGroup(
    libFiles.where((f) => !isExcluded(f)).toList(growable: false),
    lcov,
  );

  stdout
    ..writeln('Coverage core — nguồn: $lcovPath')
    ..writeln(_row('Nhóm', 'File', 'LH/LF', '%'))
    ..writeln(_line(stores, 'stores'))
    ..writeln(_line(widgets, 'widgets'))
    ..writeln(_line(core, 'CORE gộp'))
    ..writeln(_line(scenes, 'scenes (tham khảo)'))
    ..writeln(_line(all, 'toàn lib (tham khảo)'))
    ..writeln()
    ..writeln('10 file core kéo % xuống nhiều nhất (LF − LH):');
  for (final e in worstFiles(coreFiles, lcov)) {
    final miss = e.value.linesFound - e.value.linesHit;
    stdout.writeln('  ${miss.toString().padLeft(5)}  ${e.key} '
        '(${e.value.linesHit}/${e.value.linesFound})');
  }

  if (core.absent.isNotEmpty) {
    stdout
      ..writeln()
      ..writeln('VẮNG MẶT (${core.absent.length} file core không có trong '
          'lcov — % ở trên KHÔNG đáng tin, đang thổi phồng):');
    for (final f in core.absent) {
      stdout.writeln('  $f');
    }
    exitCode = 1;
  }
}

List<String> _listLibFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => normalizePath(f.path))
    .where((p) => p.endsWith('.dart'))
    .toList()
  ..sort();

String _packageName() {
  final line = File('pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((l) => l.startsWith('name:'));
  return line.substring('name:'.length).trim();
}

String _row(String a, String b, String c, String d) =>
    '${a.padRight(22)}${b.padLeft(6)}${c.padLeft(16)}${d.padLeft(9)}';

String _line(GroupSummary s, String label) {
  final pct = s.percent == null ? '-' : '${s.percent!.toStringAsFixed(1)}%';
  final absent = s.absent.isEmpty ? '' : '  (vắng ${s.absent.length})';
  return _row(
        label,
        '${s.files.length}',
        '${s.linesHit}/${s.linesFound}',
        pct,
      ) +
      absent;
}
