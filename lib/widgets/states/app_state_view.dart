import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_empty_view.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';
import 'view_state.dart';

class AppStateView<T> extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.successBuilder,
    this.emptyMessage,
    this.retryLabel,
  });

  final ViewState<T> state;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) successBuilder;
  final String? emptyMessage;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      LoadingState<T>() => const AppLoadingView(),
      EmptyState<T>() => AppEmptyView(message: emptyMessage ?? 'nothing_here'.tr),
      ErrorState<T>(:final error) =>
        AppErrorView(
          message: error.message,
          onRetry: onRetry,
          retryLabel: retryLabel ?? 'retry'.tr,
        ),
      SuccessState<T>(:final data) => successBuilder(context, data),
    };
  }
}
