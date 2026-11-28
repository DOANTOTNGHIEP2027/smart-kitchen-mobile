import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/l10n_x.dart';

/// Mã lỗi server khi bắt đầu nấu một món thực đơn đã nấu xong (409).
const String kDishAlreadyCookedCode = 'ERR_DISH_ALREADY_COOKED';

/// Báo "Món đã nấu xong" thay cho việc mở màn nấu (kèm giờ nấu nếu biết).
///
/// Dùng `Get.dialog` (không cần `BuildContext`) vì chỗ gọi thường vừa đóng
/// bottom sheet của chính nó.
Future<void> showDishCookedDialog({DateTime? cookedAt}) =>
    Get.dialog<void>(DishCookedDialog(cookedAt: cookedAt));

/// `cookedAt` trong `error.details` của 409 (nếu server gửi kèm).
DateTime? cookedAtFromDetails(Map<String, dynamic>? details) {
  final raw = details?['cookedAt'];
  return raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}

class DishCookedDialog extends StatelessWidget {
  const DishCookedDialog({super.key, this.cookedAt});

  final DateTime? cookedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final at = cookedAt;
    String two(int v) => v.toString().padLeft(2, '0');
    return AlertDialog(
      key: const ValueKey<String>('dish-cooked-dialog'),
      title: Text(l10n.dishCookedTitle),
      content: Text(
        at == null
            ? l10n.dishCookedMessage
            : l10n.dishCookedMessageAt(
                '${two(at.hour)}:${two(at.minute)}',
                '${two(at.day)}/${two(at.month)}',
              ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dishCookedClose),
        ),
      ],
    );
  }
}
