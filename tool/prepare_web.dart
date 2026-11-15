import 'dart:convert';
import 'dart:io';

/// Bundle SQLite WASM matching the resolved package and compile the Drift worker.
/// Run after `flutter create . --platforms web` and dependency resolution.
Future<void> main() async {
  final version =
      await resolvedSqliteVersion(File('.dart_tool/package_config.json'));
  final web = Directory('web');
  if (!web.existsSync()) {
    throw StateError('Create the web platform first');
  }

  await _run('curl', [
    '--fail',
    '--location',
    '--retry',
    '3',
    '--max-time',
    '120',
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$version/sqlite3.wasm',
    '--output',
    'web/sqlite3.wasm',
  ]);
  final bytes =
      await File('web/sqlite3.wasm').openRead(0, 4).expand((b) => b).toList();
  if (bytes.length != 4 ||
      bytes[0] != 0 ||
      bytes[1] != 97 ||
      bytes[2] != 115 ||
      bytes[3] != 109) {
    throw StateError('Downloaded sqlite3.wasm is not a WebAssembly module');
  }
  await _run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O4',
    'tool/drift_worker.dart',
    '-o',
    'web/drift_worker.dart.js',
  ]);
  stdout
      .writeln('Prepared SQLite $version WASM and the resolved Drift worker.');
}

Future<String> resolvedSqliteVersion(File configFile) async {
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final sqlite = packages.cast<Map<String, dynamic>>().singleWhere(
        (package) => package['name'] == 'sqlite3',
      );
  final root = Directory.fromUri(
    configFile.absolute.uri.resolve(sqlite['rootUri'] as String),
  ).uri;
  final pubspec =
      await File.fromUri(root.resolve('pubspec.yaml')).readAsString();
  final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec)
      ?.group(1);
  if (version == null || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
    throw StateError('Cannot determine the resolved sqlite3 release version');
  }
  return version;
}

Future<void> _run(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments,
      mode: ProcessStartMode.inheritStdio);
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(executable, arguments, 'Build step failed', result);
  }
}
