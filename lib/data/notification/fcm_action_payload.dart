import 'dart:convert';

const int supportedInventoryActionsSchemaVersion = 1;
const Set<String> knownInventoryActionIds = <String>{
  'COOK_TODAY',
  'MARK_USED',
  'DISCARD',
};

class FcmNotificationAction {
  const FcmNotificationAction({
    required this.id,
    required this.label,
    required this.type,
    this.target,
  });

  final String id;
  final String label;
  final String type;
  final String? target;
}

class FcmActionPayload {
  const FcmActionPayload({
    required this.data,
    required this.itemIds,
    required this.itemCount,
    required this.actions,
    this.title,
    this.body,
    this.actionItemId,
    this.actionItemName,
    this.deepLink,
    required this.renderLocally,
  });

  final Map<String, dynamic> data;
  final List<String> itemIds;
  final int itemCount;
  final List<FcmNotificationAction> actions;
  final String? title;
  final String? body;
  final String? actionItemId;
  final String? actionItemName;
  final String? deepLink;
  final bool renderLocally;

  static FcmActionPayload? tryParse(Map<String, dynamic> raw) {
    if (raw['type']?.toString() != 'INVENTORY_EXPIRY_ALERT') return null;

    final data = raw.map(
      (key, value) => MapEntry<String, dynamic>(key, value?.toString()),
    );
    final itemIds = (data['itemIds']?.toString() ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final itemCount =
        int.tryParse(data['itemCount']?.toString() ?? '') ?? itemIds.length;
    final schema =
        int.tryParse(data['actionsSchemaVersion']?.toString() ?? '') ?? 0;

    final actions = schema > supportedInventoryActionsSchemaVersion
        ? const <FcmNotificationAction>[]
        : _parseActions(data['actions']?.toString());
    return FcmActionPayload(
      data: data,
      itemIds: itemIds,
      itemCount: itemCount,
      actions: actions,
      title: data['title']?.toString(),
      body: data['body']?.toString(),
      actionItemId: data['actionItemId']?.toString(),
      actionItemName: data['actionItemName']?.toString(),
      deepLink: data['deepLink']?.toString(),
      renderLocally: data['render']?.toString() == 'LOCAL',
    );
  }

  static List<FcmNotificationAction> _parseActions(String? raw) {
    if (raw == null || raw.isEmpty) return const <FcmNotificationAction>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const <FcmNotificationAction>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((value) => Map<String, dynamic>.from(value))
          .where((value) => knownInventoryActionIds.contains(value['id']))
          .map((value) => FcmNotificationAction(
                id: value['id'] as String,
                label: value['label']?.toString().trim().isNotEmpty == true
                    ? value['label'].toString()
                    : value['id'] as String,
                type: value['type']?.toString() ?? '',
                target: value['target']?.toString(),
              ))
          .toList(growable: false);
    } catch (_) {
      return const <FcmNotificationAction>[];
    }
  }
}
