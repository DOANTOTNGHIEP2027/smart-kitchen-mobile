import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/member_row.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('tên dài có đủ chỗ, giữ các nút thao tác, cỡ chữ $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var removed = false;
      var changed = false;
      await tester.pumpAppWidget(MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(
          child: MemberRow(
            member: HouseholdMember(
              userId: 'member',
              fullName: '  Nguyễn   Thị\n Minh Anh  ',
              role: 'MEMBER',
              provider: 'GUEST',
              joinedAt: DateTime(2026, 11, 28),
            ),
            isOwner: true,
            isMe: true,
            onRemove: () => removed = true,
            onChangeRole: () => changed = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final name = find.text('Nguyễn Thị Minh Anh (bạn)');
      final paragraph = tester.renderObject<RenderParagraph>(name);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.width, greaterThan(200));
      await tester.tap(find.byKey(const ValueKey('member-remove-member')));
      await tester.tap(find.byKey(const ValueKey('member-change-role-member')));
      expect(removed, isTrue);
      expect(changed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
