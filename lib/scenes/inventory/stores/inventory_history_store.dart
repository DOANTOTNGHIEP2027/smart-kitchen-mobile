import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/inventory_api.dart';
import '../domain/inventory_transaction.dart';

enum InventoryHistoryStatus { loading, ready, error }

class InventoryHistoryStore {
  InventoryHistoryStore({
    required this.itemId,
    required InventoryApi api,
  }) : _api = api;

  final String itemId;
  final InventoryApi _api;

  final Observable<InventoryHistoryStatus> _status =
      Observable<InventoryHistoryStatus>(InventoryHistoryStatus.loading);
  final ObservableList<InventoryTransactionModel> _items =
      ObservableList<InventoryTransactionModel>();
  final Observable<ApiException?> _error = Observable<ApiException?>(null);
  final Observable<bool> _isLoadingMore = Observable<bool>(false);

  int _page = 0;
  int _totalPages = 0;

  InventoryHistoryStatus get status => _status.value;
  List<InventoryTransactionModel> get items => List.unmodifiable(_items);
  ApiException? get error => _error.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get canLoadMore => _page + 1 < _totalPages;

  Future<void> load({bool refresh = false}) async {
    if (refresh || _items.isEmpty) {
      runInAction(() {
        _status.value = InventoryHistoryStatus.loading;
        _error.value = null;
      });
    }
    try {
      final result = await _api.transactions(itemId);
      runInAction(() {
        _items
          ..clear()
          ..addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
        _status.value = InventoryHistoryStatus.ready;
      });
    } on ApiException catch (error) {
      runInAction(() {
        _error.value = error;
        _status.value = InventoryHistoryStatus.error;
      });
    } catch (error) {
      runInAction(() {
        _error.value = ServerException('ERR_UNKNOWN', error.toString());
        _status.value = InventoryHistoryStatus.error;
      });
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore.value || !canLoadMore) return;
    runInAction(() => _isLoadingMore.value = true);
    try {
      final result = await _api.transactions(itemId, page: _page + 1);
      runInAction(() {
        _items.addAll(result.items);
        _page = result.page;
        _totalPages = result.totalPages;
      });
    } on ApiException catch (error) {
      runInAction(() => _error.value = error);
    } catch (error) {
      runInAction(
        () => _error.value = ServerException('ERR_UNKNOWN', error.toString()),
      );
    } finally {
      runInAction(() => _isLoadingMore.value = false);
    }
  }
}
