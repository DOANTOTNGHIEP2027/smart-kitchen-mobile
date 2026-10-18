/// Một khung bữa trong template của household (flexible-meal-planning-screens.md
/// §5.1). Shape đối chiếu `MealSlotResponse`/`MealSlotItemRequest` thật của BE.
class MealSlotTemplateItem {
  const MealSlotTemplateItem({
    this.id,
    this.dayOfWeek,
    required this.slotKey,
    required this.label,
    required this.hour,
    required this.minute,
    required this.sortOrder,
    this.isDefault = false,
  });

  /// `null` khi đến từ DEFAULT_SLOTS ảo (GET chưa từng PUT) hoặc slot mới
  /// thêm ở draft. KHÔNG gửi lại trong PUT.
  final String? id;

  /// 0 = Thứ Hai … 6 = Chủ Nhật (BE `DayOfWeek.getValue() - 1`); `null` = mọi ngày.
  final int? dayOfWeek;

  /// `[A-Z0-9_]{1,30}`, unique trong cùng nhóm `dayOfWeek`.
  final String slotKey;
  final String label;
  final int hour;
  final int minute;

  /// FE tự gán lại theo vị trí trong nhóm `dayOfWeek` khi build PUT (D3).
  final int sortOrder;
  final bool isDefault;

  static final RegExp slotKeyPattern = RegExp(r'^[A-Z0-9_]{1,30}$');

  factory MealSlotTemplateItem.fromJson(Map<String, dynamic> json) {
    // BE trả `LocalTime` — "07:00" hoặc "07:00:00" tuỳ serializer, chỉ đọc HH:mm.
    final parts = (json['scheduledTime'] as String).split(':');
    return MealSlotTemplateItem(
      id: json['id'] as String?,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      slotKey: json['slotKey'] as String,
      label: json['label'] as String,
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
      sortOrder: (json['sortOrder'] as num).toInt(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// PUT body không có `id`/`isDefault` — BE match theo (dayOfWeek, slotKey).
  Map<String, dynamic> toPutJson() => <String, dynamic>{
        'dayOfWeek': dayOfWeek,
        'slotKey': slotKey,
        'label': label,
        'scheduledTime': timeText,
        'sortOrder': sortOrder,
      };

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  int get minutesOfDay => hour * 60 + minute;

  MealSlotTemplateItem copyWith({
    String? slotKey,
    String? label,
    int? hour,
    int? minute,
    int? sortOrder,
  }) =>
      MealSlotTemplateItem(
        id: id,
        dayOfWeek: dayOfWeek,
        slotKey: slotKey ?? this.slotKey,
        label: label ?? this.label,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        sortOrder: sortOrder ?? this.sortOrder,
        isDefault: isDefault,
      );
}
