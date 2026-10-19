import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/shopping_item.dart';
import '../stores/shopping_store.dart';

/// Tick 1 món: chiều PENDING → COMPLETED hỏi giá (optional) TRƯỚC khi gọi
/// store, để không có cửa sổ row đã PENDING_TOGGLE mà chưa có entry hàng đợi
/// (shopping-list-screen.md §9.4). Chiều ngược KHÔNG hỏi — giá sticky ở BE.
Future<void> toggleShoppingItemWithPrice(
  BuildContext context,
  ShoppingStore store,
  ShoppingItem item,
) async {
  if (!item.canToggle) return;
  if (item.status != ShoppingItemStatus.pending) {
    await store.toggle(item);
    return;
  }
  // Đóng bằng scrim/back = "Bỏ qua" → price null, vẫn tick.
  final price = await showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PriceCaptureSheet(itemName: item.name),
  );
  // Sheet có thể mở lâu: đọc lại row mới nhất (sync/WS có thể đã đổi version
  // hoặc đã tick). Không còn PENDING thì dừng — toggle tiếp sẽ BỎ tick ngược ý.
  final current = store.items.where((e) => e.id == item.id).firstOrNull;
  if (current == null ||
      current.status != ShoppingItemStatus.pending ||
      !current.canToggle) {
    return;
  }
  await store.toggle(current, price: price);
}

/// Bottom sheet nhập giá — cục bộ, không gọi API, mở được cả khi offline.
/// "Bỏ qua" luôn bấm được bằng 1 tap (ràng buộc thiết kế, không chỉ mong muốn).
class PriceCaptureSheet extends StatefulWidget {
  const PriceCaptureSheet({super.key, required this.itemName});

  final String itemName;

  /// `NUMERIC(12,2)` của BE trừ 2 chữ số thập phân → tối đa 10 chữ số.
  static const int maxDigits = 10;

  /// Chuỗi đã định dạng (`55.000`) → số VND; rỗng → `null` (bỏ qua).
  static double? parse(String text) {
    final digits = text.replaceAll('.', '');
    if (digits.isEmpty) return null;
    return double.parse(digits);
  }

  @override
  State<PriceCaptureSheet> createState() => _PriceCaptureSheetState();
}

class _PriceCaptureSheetState extends State<PriceCaptureSheet> {
  final TextEditingController _price = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = PriceCaptureSheet.parse(_price.text);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppDimens.md,
        right: AppDimens.md,
        top: AppDimens.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.itemName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimens.xs),
          Text(l10n.shoppingPriceQuestion,
              style: Theme.of(context).textTheme.bodyMedium),
          Text(l10n.shoppingPriceOptional,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimens.md),
          TextField(
            key: const ValueKey<String>('price-input'),
            controller: _price,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              const _ThousandsFormatter(),
            ],
            decoration: InputDecoration(
              labelText: l10n.shoppingPriceLabel,
              suffixText: '₫',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (value == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.xs),
              child: Text(l10n.shoppingPriceZeroHint,
                  key: const ValueKey<String>('price-zero-hint'),
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  key: const ValueKey<String>('price-skip'),
                  label: l10n.shoppingPriceSkip,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: AppButton(
                  key: const ValueKey<String>('price-save'),
                  label: l10n.shoppingPriceSave,
                  onPressed:
                      value == null ? null : () => Navigator.of(context).pop(value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chèn dấu chấm phân cách nghìn khi gõ (55000 → 55.000); input đã qua
/// `digitsOnly` nên chỉ còn chữ số.
class _ThousandsFormatter extends TextInputFormatter {
  const _ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('.', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    // Bỏ số 0 đứng đầu ("0055" → "55"; "0" giữ nguyên để gợi ý miễn phí).
    final digits = raw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    // Quá 10 chữ số → giữ nguyên giá trị cũ, KHÔNG cắt bớt chữ số cuối (cắt
    // khi chèn ở giữa sẽ âm thầm đổi giá).
    if (digits.length > PriceCaptureSheet.maxDigits) return oldValue;
    final grouped = groupThousands(digits);
    // Giữ con trỏ sau đúng số chữ số đứng trước nó — không nhảy về cuối khi
    // sửa ở giữa.
    final end = newValue.selection.isValid
        ? newValue.selection.end.clamp(0, newValue.text.length)
        : newValue.text.length;
    final before = newValue.text.substring(0, end).replaceAll('.', '').length;
    var remaining = (before - (raw.length - digits.length)).clamp(0, digits.length);
    var offset = 0;
    while (remaining > 0 && offset < grouped.length) {
      if (grouped[offset] != '.') remaining--;
      offset++;
    }
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
