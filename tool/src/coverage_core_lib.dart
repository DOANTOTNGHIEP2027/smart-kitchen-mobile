/// Logic thuần cho `tool/coverage_core.dart` (#93 — app-performance-audit
/// §10). Không I/O để unit test được.
library;

/// Nhóm của một file `lib/` khi tính coverage.
enum CoverageGroup { store, widget, scene, other }

/// Số dòng của một file trong lcov.
class LcovRecord {
  const LcovRecord(this.linesFound, this.linesHit);

  final int linesFound;
  final int linesHit;
}

/// Tổng hợp một nhóm file.
class GroupSummary {
  const GroupSummary({
    required this.files,
    required this.linesFound,
    required this.linesHit,
    required this.absent,
  });

  /// File thuộc nhóm (liệt kê từ đĩa).
  final List<String> files;
  final int linesFound;
  final int linesHit;

  /// File thuộc nhóm nhưng không có trong lcov.
  final List<String> absent;

  /// ΣLH/ΣLF × 100 — không lấy trung bình các %. `null` khi ΣLF = 0.
  double? get percent => linesFound == 0 ? null : linesHit * 100 / linesFound;
}

/// Chuẩn hoá đường dẫn: `\` → `/`, cắt về dạng `lib/...` tương đối.
String normalizePath(String path, {String? projectRoot}) {
  var p = path.replaceAll('\\', '/');
  if (projectRoot != null) {
    var root = projectRoot.replaceAll('\\', '/');
    if (!root.endsWith('/')) root = '$root/';
    if (p.toLowerCase().startsWith(root.toLowerCase())) {
      p = p.substring(root.length);
    }
  }
  if (p.startsWith('./')) p = p.substring(2);
  if (!p.startsWith('lib/')) {
    final idx = p.lastIndexOf('/lib/');
    if (idx >= 0) p = p.substring(idx + 1);
  }
  return p;
}

/// Có bị loại khỏi mọi thống kê không (§10.1).
bool isExcluded(String relPath) =>
    !relPath.startsWith('lib/') ||
    !relPath.endsWith('.dart') ||
    relPath.endsWith('.g.dart') ||
    relPath.startsWith('lib/l10n/') ||
    relPath.startsWith('lib/demo/') ||
    relPath.startsWith('lib/scenes/dev/');

/// Phân nhóm theo glob §10.1. Gọi sau [isExcluded].
CoverageGroup classify(String relPath) {
  final name = relPath.substring(relPath.lastIndexOf('/') + 1);
  if (name.endsWith('_store.dart')) return CoverageGroup.store;
  if (relPath.startsWith('lib/widgets/') ||
      (relPath.startsWith('lib/scenes/') && relPath.contains('/widgets/'))) {
    return CoverageGroup.widget;
  }
  if (name.endsWith('_scene.dart') || name.endsWith('_screen.dart')) {
    return CoverageGroup.scene;
  }
  return CoverageGroup.other;
}

/// File core = store + widget, đã trừ phần loại trừ.
bool isCore(String relPath) {
  if (isExcluded(relPath)) return false;
  final g = classify(relPath);
  return g == CoverageGroup.store || g == CoverageGroup.widget;
}

/// Đọc `SF/LF/LH` từ lcov (dự phòng đếm `DA` khi thiếu LF/LH). File xuất
/// hiện nhiều lần → giữ bản ghi có LF lớn nhất.
Map<String, LcovRecord> parseLcov(String content, {String? projectRoot}) {
  final result = <String, LcovRecord>{};
  String? current;
  int? lf, lh;
  var daFound = 0, daHit = 0;
  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      current = normalizePath(line.substring(3), projectRoot: projectRoot);
      lf = null;
      lh = null;
      daFound = 0;
      daHit = 0;
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        daFound++;
        if ((int.tryParse(parts[1]) ?? 0) > 0) daHit++;
      }
    } else if (line.startsWith('LF:')) {
      lf = int.tryParse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      lh = int.tryParse(line.substring(3));
    } else if (line == 'end_of_record' && current != null) {
      final rec = LcovRecord(lf ?? daFound, lh ?? daHit);
      final prev = result[current];
      if (prev == null || rec.linesFound >= prev.linesFound) {
        result[current] = rec;
      }
      current = null;
    }
  }
  return result;
}

/// Tổng hợp nhóm [files] theo [lcov].
GroupSummary summarizeGroup(List<String> files, Map<String, LcovRecord> lcov) {
  var found = 0, hit = 0;
  final absent = <String>[];
  for (final f in files) {
    final rec = lcov[f];
    if (rec == null) {
      absent.add(f);
      continue;
    }
    found += rec.linesFound;
    hit += rec.linesHit;
  }
  return GroupSummary(
    files: List<String>.unmodifiable(files),
    linesFound: found,
    linesHit: hit,
    absent: absent,
  );
}

/// [count] file kéo % xuống nhiều nhất (LF − LH lớn nhất).
List<MapEntry<String, LcovRecord>> worstFiles(
  List<String> files,
  Map<String, LcovRecord> lcov, {
  int count = 10,
}) {
  final entries = <MapEntry<String, LcovRecord>>[
    for (final f in files)
      if (lcov[f] != null) MapEntry<String, LcovRecord>(f, lcov[f]!),
  ]..sort((a, b) {
      final ma = a.value.linesFound - a.value.linesHit;
      final mb = b.value.linesFound - b.value.linesHit;
      return mb != ma ? mb.compareTo(ma) : a.key.compareTo(b.key);
    });
  return entries.take(count).toList();
}

/// Nội dung `test/coverage_core_imports_test.dart`: import mọi file core
/// (prefix riêng để tránh trùng tên) + 1 test rỗng.
String buildImportsFile(List<String> coreFiles, String packageName) {
  final sorted = List<String>.of(coreFiles)..sort();
  final b = StringBuffer()
    ..writeln('// GENERATED bởi `dart run tool/coverage_core.dart '
        '--write-imports` — không sửa tay.')
    ..writeln('// Import chỉ để coverage thấy mọi file core (hit = 0); '
        'prefix không được dùng là có chủ đích.')
    ..writeln('// ignore_for_file: unused_import')
    ..writeln('// ignore_for_file: no_leading_underscores_for_library_prefixes')
    ..writeln()
    ..writeln("import 'package:flutter_test/flutter_test.dart';");
  for (var i = 0; i < sorted.length; i++) {
    final uri = 'package:$packageName/${sorted[i].substring('lib/'.length)}';
    b.writeln("import '$uri' as _i$i;");
  }
  b
    ..writeln()
    ..writeln('void main() {')
    ..writeln(
        "  test('coverage core: import đủ ${sorted.length} file', () {});")
    ..writeln('}');
  return b.toString();
}
