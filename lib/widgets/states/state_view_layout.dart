import 'package:flutter/material.dart';

import '../../constants/app_dimens.dart';

/// Khung chung của [AppEmptyView]/[AppErrorView] (design-system.md §7.4).
///
/// Cha cho chiều cao hữu hạn → cuộn được, không overflow ở màn nhỏ / chữ to.
/// Cha cho chiều cao vô hạn (đang nằm trong list) → `Column` thường, vì scroll
/// view trong chiều cao vô hạn sẽ crash. Không đặt dưới `IntrinsicHeight`
/// (LayoutBuilder không hỗ trợ intrinsic).
class StateViewLayout extends StatelessWidget {
  const StateViewLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Padding(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) return Center(child: column);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
            minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          ),
          child: Center(child: column),
        ),
      );
    });
  }
}
