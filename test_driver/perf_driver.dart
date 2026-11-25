import 'package:integration_test/integration_test_driver.dart';

/// Driver cho `integration_test/performance_test.dart` (#93 §6.1): ghi mỗi key
/// của `reportData` ra `build/perf/<key>.json`.
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        for (final entry in data.entries) {
          await writeResponseData(
            <String, dynamic>{entry.key: entry.value},
            testOutputFilename: entry.key,
            destinationDirectory: 'build/perf',
          );
        }
      },
    );
