import 'package:flutter/material.dart';

import '../../utils/l10n_x.dart';

/// Chip hạn dùng dùng chung (#239 F8): cất đồ đi chợ vào kho, thẻ scan kho,
/// thẻ hoá đơn không khớp. Ba trạng thái: trống ("Thêm hạn dùng"), gợi ý
/// ("HSD … · gợi ý"), đã chọn ("HSD …"). Luôn hiện — kể cả khi chưa có ngày —
/// để người dùng tự thêm được.
class ExpiryDateChip extends StatelessWidget {
  const ExpiryDateChip({
    super.key,
    required this.date,
    required this.suggested,
    required this.onChanged,
    this.enabled = true,
    this.suggestedLabel,
  });

  final DateTime? date;

  /// Ngày đang hiện là gợi ý (AI/lịch sử/bảng mặc định), người dùng chưa sửa.
  final bool suggested;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  /// Nhãn riêng cho ngày gợi ý (vd. "AI ước lượng" của scan kho); mặc định
  /// dùng [AppLocalizations.expiryChipSuggested].
  final String Function(String date)? suggestedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = date;
    final String label;
    if (current == null) {
      label = l10n.expiryChipAdd;
    } else {
      final formatted = MaterialLocalizations.of(context).formatCompactDate(current);
      label = suggested
          ? (suggestedLabel?.call(formatted) ?? l10n.expiryChipSuggested(formatted))
          : l10n.expiryChipSet(formatted);
    }
    return ActionChip(
      key: const ValueKey<String>('expiry-date-chip'),
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        current == null ? Icons.add : Icons.event_outlined,
        size: 14,
      ),
      label: Text(label),
      onPressed: enabled ? () => _pick(context) : null,
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = date == null
        ? today
        : DateTime(date!.year, date!.month, date!.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) onChanged(picked);
  }
}
