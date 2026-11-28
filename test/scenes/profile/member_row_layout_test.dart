import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/member_row.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('tên thành viên và menu thao tác, cỡ chữ $scale',
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
              fullName: 'Nguyễn Thị Minh Anh',
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
      expect(find.text('Nguyễn Thị Minh Anh (bạn)'), findsOneWidget);
      final actions = find.byKey(const ValueKey('member-actions-member'));
      expect(find.byKey(const ValueKey('member-remove-member')), findsNothing);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('member-remove-member')));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
      expect(changed, isFalse);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('member-change-role-member')));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
      expect(changed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
