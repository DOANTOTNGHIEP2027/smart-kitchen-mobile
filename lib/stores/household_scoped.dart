import 'package:mobx/mobx.dart';

import 'session_store.dart';

/// Store `permanent` (sống qua logout/đổi household) bám đúng household hiện
/// tại (OD-32/OD-33).
///
/// [householdEpoch] tăng MỖI lần household đổi. Tác vụ bất đồng bộ chụp epoch
/// lúc bắt đầu và bỏ kết quả nếu [isStaleEpoch] — so epoch thay vì so
/// `householdId` vì đổi A→B→A trong lúc request bay thì householdId lại khớp
/// dù dữ liệu đã lẫn token của B.
mixin HouseholdScoped {
  int _epoch = 0;
  bool _bound = false;
  String? _boundHousehold;
  ReactionDisposer? _householdReaction;

  int get householdEpoch => _epoch;

  bool isStaleEpoch(int epoch) => epoch != _epoch;

  /// `false` sau [unbindHousehold] (dispose) — tác vụ đang bay không được tự
  /// chạy bù cho store đã huỷ.
  bool get isHouseholdBound => _bound;

  /// Gọi đầu `init()`. Lần đầu: đăng ký [onChange] chạy mỗi khi
  /// `session.householdId` đổi. Trả `true` khi household khác lần bind trước
  /// (hoặc lần đầu) → caller huỷ luồng cũ, xoá dữ liệu cũ, nghe lại; `false` →
  /// cùng household, no-op (màn dựng lại không mở luồng/sync trùng).
  bool rebindHousehold(SessionStore session, void Function() onChange) {
    // Tăng epoch NGAY trong reaction, không phụ thuộc [onChange] có gọi lại
    // rebind đồng bộ hay không.
    _householdReaction ??= reaction<String?>((_) => session.householdId, (_) {
      _epoch++;
      onChange();
    });
    final householdId = session.householdId;
    if (_bound && householdId == _boundHousehold) return false;
    _bound = true;
    _boundHousehold = householdId;
    _epoch++;
    return true;
  }

  void unbindHousehold() {
    _householdReaction?.call();
    _householdReaction = null;
    _bound = false;
    // Hết nghe đổi household → tác vụ đang bay coi như cũ, không ghi state.
    _epoch++;
  }
}
