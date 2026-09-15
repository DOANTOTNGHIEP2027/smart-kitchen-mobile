import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Giả lập plugin `flutter_secure_storage` bằng một Map in-memory.
///
/// `TokenStorage` giữ nguyên như spec (§8) — chỉ tầng platform channel bên
/// dưới bị thay, nên test vẫn chạy đúng code production.
class FakeSecureStorageChannel {
  static const MethodChannel _channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> values = <String, String>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      final args = (call.arguments as Map<Object?, Object?>?) ??
          const <Object?, Object?>{};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          values[key!] = args['value'] as String;
          return null;
        case 'read':
          return values[key];
        case 'delete':
          values.remove(key);
          return null;
        case 'deleteAll':
          values.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(values);
        case 'containsKey':
          return values.containsKey(key);
        default:
          return null;
      }
    });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    values.clear();
  }
}
