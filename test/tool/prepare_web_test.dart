import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/prepare_web.dart';

void main() {
  for (final trailingSlash in [false, true]) {
    test(
        'resolved sqlite version handles rootUri trailing slash=$trailingSlash',
        () async {
      final temp =
          await Directory.systemTemp.createTemp('sqlite_version_test_');
      addTearDown(() => temp.delete(recursive: true));
      final package = await Directory('${temp.path}/sqlite3').create();
      await File('${package.path}/pubspec.yaml')
          .writeAsString('name: sqlite3\nversion: 3.5.2\n');
      final config = File('${temp.path}/package_config.json');
      final uri = package.uri.toString();
      await config.writeAsString(jsonEncode({
        'packages': [
          {
            'name': 'sqlite3',
            'rootUri': trailingSlash ? uri : uri.substring(0, uri.length - 1)
          }
        ],
      }));
      expect(await resolvedSqliteVersion(config), '3.5.2');
    });
  }

  test(
      'missing release version fails instead of downloading an arbitrary binary',
      () async {
    final temp = await Directory.systemTemp.createTemp('sqlite_version_test_');
    addTearDown(() => temp.delete(recursive: true));
    await File('${temp.path}/pubspec.yaml').writeAsString('name: sqlite3\n');
    final config = File('${temp.path}/package_config.json');
    await config.writeAsString(jsonEncode({
      'packages': [
        {'name': 'sqlite3', 'rootUri': temp.uri.toString()}
      ],
    }));
    expect(resolvedSqliteVersion(config), throwsStateError);
  });
}
