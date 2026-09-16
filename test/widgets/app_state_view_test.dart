import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_state_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../helpers/pump_app.dart';

void main() {
  Widget buildView(
    ViewState<String> state, {
    VoidCallback? onRetry,
    String? emptyMessage,
  }) =>
      AppStateView<String>(
        state: state,
        onRetry: onRetry ?? () {},
        emptyMessage: emptyMessage,
        successBuilder: (BuildContext context, String data) => Text(data),
      );

  testWidgets('LoadingState → spinner', (WidgetTester tester) async {
    await tester.pumpAppWidget(buildView(const LoadingState<String>()));

    expect(find.byType(AppLoadingView), findsOneWidget);
  });

  testWidgets('EmptyState → dùng message của caller', (WidgetTester tester) async {
    await tester.pumpAppWidget(
      buildView(const EmptyState<String>(), emptyMessage: 'No items yet'),
    );

    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);
  });

  testWidgets('EmptyState không có message → fallback i18n',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(buildView(const EmptyState<String>()));

    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
  });

  testWidgets('ErrorState → hiện message của ApiException + nút retry chạy',
      (WidgetTester tester) async {
    var retried = 0;
    await tester.pumpAppWidget(
      buildView(
        ErrorState<String>(ServerException('ERR_INTERNAL', 'Server error')),
        onRetry: () => retried++,
      ),
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Server error'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('SuccessState → render successBuilder', (WidgetTester tester) async {
    await tester.pumpAppWidget(buildView(const SuccessState<String>('done')));

    expect(find.text('done'), findsOneWidget);
  });
}
