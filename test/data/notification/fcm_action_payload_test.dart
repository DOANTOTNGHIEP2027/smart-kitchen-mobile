import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/notification/fcm_action_payload.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_api.dart';

void main() {
  Map<String, dynamic> payload(
      {String schema = '1', String? render = 'LOCAL'}) {
    return <String, dynamic>{
      'type': 'INVENTORY_EXPIRY_ALERT',
      'itemIds': 'i1,i2',
      'itemCount': '5',
      'deepLink': 'smartkitchen://inventory?filter=expiring',
      if (render != null) 'render': render,
      'title': 'Cảnh báo hết hạn',
      'body': 'Có thực phẩm sắp hết hạn',
      'actionsSchemaVersion': schema,
      'actionItemId': 'i1',
      'actions': jsonEncode(<Map<String, String>>[
        <String, String>{
          'id': 'COOK_TODAY',
          'label': 'Nấu hôm nay',
          'type': 'DEEP_LINK',
          'target': 'smartkitchen://meal-plan?source=expiry-alert',
        },
        <String, String>{
          'id': 'MARK_USED',
          'label': 'Đã dùng',
          'type': 'API_CALL',
        },
        <String, String>{
          'id': 'UNKNOWN_FUTURE_ACTION',
          'label': 'Không biết',
          'type': 'API_CALL',
        },
      ]),
    };
  }

  test('parse string-only payload và bỏ action id lạ', () {
    final result = FcmActionPayload.tryParse(payload())!;

    expect(result.renderLocally, isTrue);
    expect(result.itemIds, <String>['i1', 'i2']);
    expect(result.itemCount, 5);
    expect(result.actions.map((value) => value.id),
        <String>['COOK_TODAY', 'MARK_USED']);
    expect(result.actionItemId, 'i1');
  });

  test('schema mới hơn vẫn parse notification nhưng bỏ toàn bộ nút', () {
    final result = FcmActionPayload.tryParse(payload(schema: '99'))!;

    expect(result.renderLocally, isTrue);
    expect(result.actions, isEmpty);
  });

  test('không có render không được tự dựng local notification', () {
    final result = FcmActionPayload.tryParse(payload(render: null))!;
    expect(result.renderLocally, isFalse);
  });

  test('loại notification khác không thuộc consumer inventory', () {
    expect(
      FcmActionPayload.tryParse(<String, dynamic>{'type': 'SHOPPING_REMINDER'}),
      isNull,
    );
  });

  test('quick-action response mapper giữ applied=false và reason lạ', () {
    final result = inventoryQuickActionResultFromJson(<String, dynamic>{
      'itemId': 'i1',
      'itemName': 'Cà chua',
      'action': 'MARK_USED',
      'applied': false,
      'transactionReason': 'CORRECTED',
    });

    expect(result.applied, isFalse);
    expect(result.transactionReason, 'CORRECTED');
  });
}
