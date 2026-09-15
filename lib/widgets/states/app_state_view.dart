import 'package:flutter/material.dart';

import 'app_empty_view.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';
import 'view_state.dart';

/// Render bốn nhánh của [ViewState] (fe-app-shell.md §10.3).
///
/// ```dart
/// Observer(builder: (_) => AppStateView<List<InventoryItem>>(
///   state: store.itemsState,
///   onRetry: store.reload,
///   successBuilder: (context, items) => ItemsListView(items),
/// ));
/// ```
class AppStateView<T> extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.successBuilder,
    this.emptyMessage,
  });

  final ViewState<T> state;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) successBuilder;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) => switch (state) {
        LoadingState<T>() => const AppLoadingView(),
        EmptyState<T>() => AppEmptyView(message: emptyMessage),
        ErrorState<T>(:final error) =>
          AppErrorView(message: error.message, onRetry: onRetry),
        SuccessState<T>(:final data) => successBuilder(context, data),
      };
}
