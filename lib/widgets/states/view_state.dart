import '../../data/network/api_exception.dart';

sealed class ViewState<T> {
  const ViewState();
}

class LoadingState<T> extends ViewState<T> {
  const LoadingState();
}

class SuccessState<T> extends ViewState<T> {
  const SuccessState(this.data);

  final T data;
}

class EmptyState<T> extends ViewState<T> {
  const EmptyState();
}

class ErrorState<T> extends ViewState<T> {
  const ErrorState(this.error);

  final ApiException error;
}
