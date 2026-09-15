import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/jwt_claims.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test('decode payload và trả claim snake_case', () {
    final token = fakeJwt(<String, dynamic>{
      'sub': 'u1',
      'household_id': 'h1',
      'role': 'OWNER',
      'provider': 'GOOGLE',
    });

    final claims = decodeJwtPayload(token);

    expect(claims['household_id'], 'h1');
    expect(claims['role'], 'OWNER');
    expect(claims['provider'], 'GOOGLE');
  });

  test('token dị dạng suy biến thành "không có claim" thay vì throw', () {
    expect(decodeJwtPayload('not-a-jwt'), isEmpty);
    expect(decodeJwtPayload('a.b.c'), isEmpty);
    expect(decodeJwtPayload(''), isEmpty);
  });
}
