import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fixtures/demo_fixtures.dart';

/// Backend giả lập cho bản demo — **chỉ bật khi `DEMO_MODE=true`**.
///
/// Thay tầng transport của Dio, không đụng bất kỳ dòng nào trong repository,
/// use case hay store: mọi thứ phía trên vẫn chạy đúng code production, đi qua
/// đủ pipeline interceptor và envelope thật. Nhờ vậy demo chứng minh được
/// luồng thật chứ không phải một UI rỗng.
///
/// Response bám đúng `docs/contracts/openapi/{auth-jwt,household-invite-role}.yaml`.
///
/// Kịch bản demo:
/// - OTP đúng là `123456`; mã khác trả `ERR_AUTH_OTP_INVALID`.
/// - Đăng nhập: mật khẩu `password` là đúng; sai 3 lần liên tiếp → khoá 429.
/// - `taken@demo.local` đã tồn tại → `ERR_AUTH_003`.
/// - Mã mời hợp lệ: `DEMO1234`. `EXPIRED1` → hết hạn. `RACED123` → bị dùng mất.
/// - Mã mời do chính demo tạo ra khi tạo Nhà cũng dùng được ngay.
class DemoBackendAdapter implements HttpClientAdapter {
  DemoBackendAdapter();

  static const String validInviteCode = 'DEMO1234';
  static const String expiredInviteCode = 'EXPIRED1';
  static const String racedInviteCode = 'RACED123';
  static const String correctOtp = '123456';
  static const String correctPassword = 'password';
  static const String takenEmail = 'taken@demo.local';

  static const Duration _latency = Duration(milliseconds: 450);

  /// State phiên demo — quyết định claim mà `/auth/refresh` trả về.
  String? _householdId;
  String _role = 'OWNER';
  String _provider = 'EMAIL';
  String _userId = 'demo-user-0001';
  String _fullName = 'Người dùng demo';
  String? _email;
  int _failedLogins = 0;
  int _otpSends = 0;
  final Set<String> _issuedInviteCodes = <String>{};
  final Set<String> _usedInviteCodes = <String>{};
  final List<Map<String, dynamic>> _inventory = DemoFixtures.inventory()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: true);
  final Map<String, Map<String, dynamic>> _plans =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _votes =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _cookingSessions =
      <String, Map<String, dynamic>>{};
  late Map<String, dynamic> _healthProfile = DemoFixtures.healthProfile();
  var _inventorySequence = 4;
  var _dishSequence = 1;
  var _voteSequence = 1;
  var _cookingSequence = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(_latency); // để spinner thật sự nhìn thấy được
    final body = options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : const <String, dynamic>{};
    return _route(options, body);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _route(RequestOptions options, Map<String, dynamic> body) {
    final path = options.path;

    final featureResponse = _routeFeature(options, body);
    if (featureResponse != null) return featureResponse;

    if (path.startsWith('/api/v1/households/invites/')) {
      return _previewInvite(
        path.substring('/api/v1/households/invites/'.length),
      );
    }

    return switch (path) {
      '/api/v1/auth/google' => _googleLogin(),
      '/api/v1/auth/email/register' => _register(body),
      '/api/v1/auth/email/send-otp' => _sendOtp(),
      '/api/v1/auth/email/verify-otp' => _verifyOtp(body),
      '/api/v1/auth/email/login' => _login(body),
      '/api/v1/auth/refresh' => _refresh(),
      '/api/v1/auth/revoke' => _okEmpty(200),
      '/api/v1/auth/revoke-all' => _okEmpty(200),
      '/api/v1/auth/qr-join' => _qrJoin(body),
      '/api/v1/auth/upgrade-profile' => _upgradeProfile(body),
      '/api/v1/households' => _createHousehold(body),
      '/api/v1/households/join' => _joinHousehold(body),
      _ => _error(404, 'ERR_NOT_FOUND', 'Demo chưa mô phỏng endpoint này'),
    };
  }

  /// Toàn bộ endpoint demo cho các feature sau onboarding. Chúng dùng cùng
  /// response envelope với backend thật để API/store/mapper production được
  /// chạy nguyên vẹn trong DEMO_MODE.
  ResponseBody? _routeFeature(
    RequestOptions options,
    Map<String, dynamic> body,
  ) {
    final path = options.path;
    final method = options.method.toUpperCase();

    if (path == '/api/v1/users/me/health-profile') {
      return method == 'GET' ? _ok(200, _healthProfile) : _updateHealth(body);
    }
    if (path == '/api/v1/allergens') return _ok(200, DemoFixtures.allergens);
    if (path == '/api/v1/users/me/allergens') return _updateAllergens(body);
    if (path == '/api/v1/households/me') return _ok(200, _householdRoster());
    if (path == '/api/v1/households/invites' && method == 'POST') {
      return _ok(201, <String, dynamic>{
        'code': validInviteCode,
        'link': 'smartkitchen://join/$validInviteCode',
        'expiresAt': DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String(),
      });
    }
    final healthSummary = RegExp(r'^/api/v1/users/([^/]+)/health-summary$')
        .firstMatch(path);
    if (healthSummary != null && method == 'GET') {
      return _ok(200, <String, dynamic>{
        'userId': healthSummary.group(1),
        'dietType': _healthProfile['dietType'],
        'allergens': _healthProfile['allergens'],
      });
    }

    if (path == '/api/v1/inventory-items') {
      return switch (method) {
        'GET' => _listInventory(options),
        'POST' => _createInventory(body),
        _ => _error(405, 'ERR_DEMO_METHOD', 'Phương thức này chưa được hỗ trợ trong bản demo.'),
      };
    }
    final inventoryMatch = RegExp(r'^/api/v1/inventory-items/([^/]+)$')
        .firstMatch(path);
    if (inventoryMatch != null) {
      return switch (method) {
        'GET' => _getInventory(inventoryMatch.group(1)!),
        'PUT' => _updateInventory(inventoryMatch.group(1)!, body),
        'DELETE' => _deleteInventory(inventoryMatch.group(1)!, body),
        _ => _error(405, 'ERR_DEMO_METHOD', 'Phương thức này chưa được hỗ trợ trong bản demo.'),
      };
    }

    if (path == '/api/v1/meal-plans/current' && method == 'GET') {
      return _ok(200, _currentPlan());
    }
    if (path == '/api/v1/meal-plans' && method == 'POST') {
      final weekStart = body['weekStart'] as String? ?? _currentWeekStart();
      return _ok(201, _planForWeek(weekStart));
    }
    final voteMatch = RegExp(
      r'^/api/v1/meal-plans/([^/]+)/slots/([^/]+)/dishes/([^/]+)/vote(?:/(open|result|close))?$',
    ).firstMatch(path);
    if (voteMatch != null) {
      return _routeVote(
        method: method,
        planId: voteMatch.group(1)!,
        slotId: voteMatch.group(2)!,
        dishId: voteMatch.group(3)!,
        action: voteMatch.group(4),
        body: body,
      );
    }
    final dishMatch = RegExp(
      r'^/api/v1/meal-plans/([^/]+)/slots/([^/]+)/dishes(?:/([^/]+))?$',
    ).firstMatch(path);
    if (dishMatch != null) {
      return _routeDish(
        method: method,
        planId: dishMatch.group(1)!,
        slotId: dishMatch.group(2)!,
        dishId: dishMatch.group(3),
        body: body,
      );
    }
    final planMatch = RegExp(r'^/api/v1/meal-plans/([^/]+)$').firstMatch(path);
    if (planMatch != null && method == 'GET') {
      final plan = _plans[planMatch.group(1)];
      return plan == null
          ? _error(404, 'ERR_PLAN_NOT_FOUND', 'Không tìm thấy kế hoạch bữa ăn.')
          : _ok(200, plan);
    }

    final recipeMatch = RegExp(r'^/api/v1/recipes/([^/]+)$').firstMatch(path);
    if (recipeMatch != null && method == 'GET') {
      return _ok(200, DemoFixtures.recipe(recipeMatch.group(1)!));
    }
    if (path == '/api/v1/cooking/sessions' && method == 'POST') {
      return _startCooking(body);
    }
    final cookingAdvance = RegExp(
      r'^/api/v1/cooking/sessions/([^/]+)/advance-step$',
    ).firstMatch(path);
    if (cookingAdvance != null && method == 'POST') {
      return _advanceCooking(cookingAdvance.group(1)!, body);
    }
    final cookingComplete = RegExp(
      r'^/api/v1/cooking/sessions/([^/]+)/complete$',
    ).firstMatch(path);
    if (cookingComplete != null && method == 'POST') {
      return _completeCooking(cookingComplete.group(1)!);
    }
    final cookingAbandon = RegExp(
      r'^/api/v1/cooking/sessions/([^/]+)/abandon$',
    ).firstMatch(path);
    if (cookingAbandon != null && method == 'POST') {
      return _abandonCooking(cookingAbandon.group(1)!);
    }
    final cookingSession = RegExp(r'^/api/v1/cooking/sessions/([^/]+)$')
        .firstMatch(path);
    if (cookingSession != null && method == 'GET') {
      return _getCookingSession(cookingSession.group(1)!);
    }
    return null;
  }

  // ── Auth ─────────────────────────────────────────────────────────

  ResponseBody _googleLogin() {
    _provider = 'GOOGLE';
    _email = 'demo@gmail.com';
    _fullName = 'Demo Google';
    return _ok(200, <String, dynamic>{
      ..._sessionPayload(),
      'accountLinked': false,
    });
  }

  ResponseBody _register(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase();
    if (email == takenEmail) {
      return _error(409, 'ERR_AUTH_003', 'Email này đã được đăng ký.');
    }
    _email = email;
    _fullName = body['fullName'] as String? ?? _fullName;
    _provider = 'EMAIL';
    _otpSends = 1;
    return _ok(201, <String, dynamic>{
      'requiresOtpVerification': true,
      'message': 'OTP đã được gửi đến email của bạn',
      'email': email,
    });
  }

  /// Luôn 200 kể cả email không tồn tại (chống dò email) — trừ khi chạm giới
  /// hạn 3 OTP đang active.
  ResponseBody _sendOtp() {
    _otpSends++;
    if (_otpSends > 3) {
      return _error(429, 'ERR_AUTH_OTP_LIMIT', 'Bạn đã yêu cầu OTP quá nhiều lần.');
    }
    return _ok(200, <String, dynamic>{
      'message': 'Nếu email này đã đăng ký, OTP đã được gửi',
    });
  }

  ResponseBody _verifyOtp(Map<String, dynamic> body) {
    if ((body['otp'] as String? ?? '') != correctOtp) {
      return _error(400, 'ERR_AUTH_OTP_INVALID', 'Mã OTP không đúng hoặc đã hết hạn.');
    }
    _otpSends = 0;
    _email = body['email'] as String? ?? _email;
    return _ok(200, _sessionPayload());
  }

  ResponseBody _login(Map<String, dynamic> body) {
    if (_failedLogins >= 3) {
      return _error(429, 'ERR_AUTH_RATE_LIMIT', 'Bạn đã nhập sai quá nhiều lần. Hãy thử lại sau.');
    }
    if ((body['password'] as String? ?? '') != correctPassword) {
      _failedLogins++;
      return _error(401, 'ERR_AUTH_004', 'Email hoặc mật khẩu chưa đúng.');
    }
    _failedLogins = 0;
    _email = body['email'] as String? ?? _email;
    _provider = 'EMAIL';
    return _ok(200, _sessionPayload());
  }

  ResponseBody _refresh() => _ok(200, <String, dynamic>{
        'accessToken': _accessToken(),
        'refreshToken': 'demo-refresh-${DateTime.now().microsecondsSinceEpoch}',
        'expiresIn': 900,
      });

  /// Khác mọi response auth khác: JWT được phát hành kèm sẵn claim household,
  /// nên không cần refresh (S8.10).
  ResponseBody _qrJoin(Map<String, dynamic> body) {
    final code = (body['inviteCode'] as String? ?? '').toUpperCase();
    final failure = _inviteFailure(code, invalidCode: 'ERR_AUTH_INVITE_INVALID');
    if (failure != null) return failure;

    _usedInviteCodes.add(code);
    _householdId = 'demo-household-0001';
    _role = 'MEMBER';
    _provider = 'GUEST';
    _userId = 'demo-guest-0002';
    _fullName = body['displayName'] as String? ?? 'Thành viên';
    _email = null;
    return _ok(201, <String, dynamic>{
      ..._sessionPayload(),
      'householdId': _householdId,
      'role': _role,
      'requiresProfileCompletion': true,
    });
  }

  ResponseBody _upgradeProfile(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase();
    if (email == takenEmail) {
      return _error(409, 'ERR_AUTH_003', 'Email này đã được đăng ký.');
    }
    _email = email;
    _provider = 'EMAIL';
    _fullName = body['fullName'] as String? ?? _fullName;
    _otpSends = 1;
    return _ok(200, <String, dynamic>{
      'accessToken': _accessToken(),
      'refreshToken': 'demo-refresh-upgrade',
      'expiresIn': 900,
      'requiresOtpVerification': true,
      'message': 'Vui lòng xác minh email để hoàn tất.',
    });
  }

  // ── Household ────────────────────────────────────────────────────

  ResponseBody _createHousehold(Map<String, dynamic> body) {
    if (_householdId != null) {
      return _error(409, 'ERR_HH_003', 'Tài khoản này đã thuộc một Nhà.');
    }
    _householdId = 'demo-household-0001';
    _role = 'OWNER';
    final code = _generateInviteCode();
    _issuedInviteCodes.add(code);
    return _ok(201, <String, dynamic>{
      'id': _householdId,
      'name': body['name'] as String? ?? 'Gia đình demo',
      'ownerId': _userId,
      'inviteCode': code,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  ResponseBody _previewInvite(String rawCode) {
    final code = rawCode.toUpperCase();
    if (code == expiredInviteCode) {
      return _error(400, 'ERR_HH_002', 'Mã mời đã hết hạn hoặc không hợp lệ.');
    }
    if (!_isKnownCode(code)) {
      return _error(400, 'ERR_HH_002', 'Mã mời đã hết hạn hoặc không hợp lệ.');
    }
    return _ok(200, <String, dynamic>{
      'householdName': 'Gia đình Nguyễn',
      'ownerName': 'Nguyễn Đình Phúc',
      'memberCount': 3,
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 72))
          .toIso8601String(),
      'isValid': true,
    });
  }

  ResponseBody _joinHousehold(Map<String, dynamic> body) {
    final code = (body['code'] as String? ?? '').toUpperCase();
    final failure = _inviteFailure(code, invalidCode: 'ERR_HH_002');
    if (failure != null) return failure;

    _usedInviteCodes.add(code);
    _householdId = 'demo-household-0001';
    _role = 'MEMBER';
    return _ok(200, <String, dynamic>{
      'householdId': _householdId,
      'householdName': 'Gia đình Nguyễn',
      'role': _role,
      'requiresTokenRefresh': true,
    });
  }

  // ── Profile / family ─────────────────────────────────────────────

  ResponseBody _updateHealth(Map<String, dynamic> body) {
    _healthProfile = <String, dynamic>{
      ..._healthProfile,
      ...body,
      'userId': _userId,
      'allergens': _healthProfile['allergens'],
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return _ok(200, _healthProfile);
  }

  ResponseBody _updateAllergens(Map<String, dynamic> body) {
    final ids = (body['allergenIds'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => (value as num).toInt())
        .toSet();
    final selected = DemoFixtures.allergens
        .where((allergen) => ids.contains(allergen['id']))
        .map((allergen) => Map<String, dynamic>.from(allergen))
        .toList(growable: false);
    _healthProfile = <String, dynamic>{
      ..._healthProfile,
      'allergens': selected,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return _ok(200, selected);
  }

  Map<String, dynamic> _householdRoster() => <String, dynamic>{
        'id': _householdId ?? DemoFixtures.householdId,
        'name': 'Gia đình demo',
        'ownerId': DemoFixtures.ownerId,
        'role': _role,
        'memberCount': 3,
        'members': <Map<String, dynamic>>[
          <String, dynamic>{
            'userId': _userId,
            'fullName': _fullName,
            'avatarUrl': null,
            'role': _role,
            'provider': _provider,
            'joinedAt': '2026-09-01T08:00:00.000Z',
          },
          <String, dynamic>{
            'userId': 'demo-member-0002',
            'fullName': 'Minh Anh',
            'avatarUrl': null,
            'role': 'MEMBER',
            'provider': 'EMAIL',
            'joinedAt': '2026-09-02T08:00:00.000Z',
          },
          <String, dynamic>{
            'userId': 'demo-member-0003',
            'fullName': 'Bà Ngoại',
            'avatarUrl': null,
            'role': 'MEMBER',
            'provider': 'EMAIL',
            'joinedAt': '2026-09-03T08:00:00.000Z',
          },
        ],
      };

  // ── Inventory ────────────────────────────────────────────────────

  ResponseBody _listInventory(RequestOptions options) {
    final page = int.tryParse('${options.queryParameters['page'] ?? 0}') ?? 0;
    final size = int.tryParse('${options.queryParameters['size'] ?? 100}') ?? 100;
    final start = page * size;
    final items = start >= _inventory.length
        ? const <Map<String, dynamic>>[]
        : _inventory.skip(start).take(size).map(_copyMap).toList(growable: false);
    return _ok(200, <String, dynamic>{
      'items': items,
      'page': page,
      'size': size,
      'totalElements': _inventory.length,
      'totalPages': _inventory.isEmpty ? 0 : (_inventory.length / size).ceil(),
    });
  }

  ResponseBody _getInventory(String id) {
    final item = _inventory.where((item) => item['id'] == id).firstOrNull;
    return item == null
        ? _error(404, 'ERR_INVENTORY_NOT_FOUND', 'Không tìm thấy mặt hàng trong kho.')
        : _ok(200, item);
  }

  ResponseBody _createInventory(Map<String, dynamic> body) {
    final now = DateTime.now().toUtc().toIso8601String();
    final quantity = (body['quantity'] as num?)?.toDouble() ?? 0;
    final threshold = (body['lowStockThreshold'] as num?)?.toDouble();
    final item = <String, dynamic>{
      'id': 'demo-inventory-${_inventorySequence++}',
      'householdId': _householdId ?? DemoFixtures.householdId,
      'name': body['name'] as String? ?? 'Mặt hàng mới',
      'category': body['category'] as String?,
      'quantity': quantity,
      'unit': body['unit'] as String? ?? 'CÁI',
      'displayQuantity': quantity,
      'displayUnit': body['unit'] as String? ?? 'CÁI',
      'lowStockThreshold': threshold,
      'expiryDate': body['expiryDate'],
      'note': body['note'] as String?,
      'version': 1,
      'isLowStock': threshold != null && quantity <= threshold,
      'isExpiringSoon': _isExpiringSoon(body['expiryDate'] as String?),
      'createdBy': _userId,
      'createdAt': now,
      'updatedAt': now,
    };
    _inventory.add(item);
    return _ok(201, item);
  }

  ResponseBody _updateInventory(String id, Map<String, dynamic> body) {
    final index = _inventory.indexWhere((item) => item['id'] == id);
    if (index < 0) {
      return _error(404, 'ERR_INVENTORY_NOT_FOUND', 'Không tìm thấy mặt hàng trong kho.');
    }
    final previous = _inventory[index];
    final expectedVersion = (body['version'] as num?)?.toInt();
    if (expectedVersion != previous['version']) {
      return _error(
        409,
        'ERR_INVENTORY_VERSION_CONFLICT',
        'Mặt hàng đã được thay đổi ở nơi khác. Hãy tải lại và thử lại.',
      );
    }
    final quantity = (body['quantity'] as num?)?.toDouble() ??
        (previous['quantity'] as double);
    final threshold = (body['lowStockThreshold'] as num?)?.toDouble();
    final updated = <String, dynamic>{
      ...previous,
      ...body,
      'quantity': quantity,
      'displayQuantity': quantity,
      'displayUnit': body['unit'] ?? previous['displayUnit'],
      'lowStockThreshold': threshold,
      'version': (previous['version'] as int) + 1,
      'isLowStock': threshold != null && quantity <= threshold,
      'isExpiringSoon': _isExpiringSoon(body['expiryDate'] as String?),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    _inventory[index] = updated;
    return _ok(200, updated);
  }

  ResponseBody _deleteInventory(String id, Map<String, dynamic> body) {
    final index = _inventory.indexWhere((item) => item['id'] == id);
    if (index < 0) {
      return _error(404, 'ERR_INVENTORY_NOT_FOUND', 'Mặt hàng này đã không còn trong kho.');
    }
    final expectedVersion = (body['version'] as num?)?.toInt();
    if (expectedVersion != _inventory[index]['version']) {
      return _error(
        409,
        'ERR_INVENTORY_VERSION_CONFLICT',
        'Mặt hàng đã được thay đổi ở nơi khác. Hãy tải lại và thử lại.',
      );
    }
    _inventory.removeAt(index);
    return _empty(204);
  }

  // ── Meal plan / vote ─────────────────────────────────────────────

  Map<String, dynamic> _currentPlan() => _planForWeek(_currentWeekStart());

  Map<String, dynamic> _planForWeek(String weekStart) {
    final id = 'demo-plan-$weekStart';
    return _plans.putIfAbsent(id, () => DemoFixtures.mealPlan(weekStart));
  }

  ResponseBody _routeDish({
    required String method,
    required String planId,
    required String slotId,
    required String? dishId,
    required Map<String, dynamic> body,
  }) {
    final plan = _plans[planId];
    if (plan == null) {
      return _error(404, 'ERR_PLAN_NOT_FOUND', 'Không tìm thấy kế hoạch bữa ăn.');
    }
    final slot = _slotOf(plan, slotId);
    if (slot == null) {
      return _error(404, 'ERR_SLOT_NOT_FOUND', 'Không tìm thấy khung bữa ăn.');
    }
    if (dishId == null && method == 'POST') {
      final dishes = slot['dishes'] as List<dynamic>;
      final dish = <String, dynamic>{
        'id': 'demo-dish-${_dishSequence++}',
        'slotId': slotId,
        'sortOrder': dishes.length,
        'status': 'EMPTY',
        'recipe': null,
      };
      dishes.add(dish);
      return _ok(201, dish);
    }
    final dish = _dishOf(slot, dishId);
    if (dish == null) {
      return _error(404, 'ERR_DISH_NOT_FOUND', 'Không tìm thấy món trong khung bữa ăn.');
    }
    if (method == 'PUT') {
      final recipeId = body['recipeId'] as String?;
      final recipeName = body['recipeName'] as String?;
      if (recipeId == null || recipeName == null) {
        return _error(400, 'ERR_PLAN_INPUT', 'Cần chọn một món ăn trước khi xác nhận.');
      }
      dish
        ..['status'] = 'CONFIRMED'
        ..['recipe'] = <String, dynamic>{
          'recipeId': recipeId,
          'recipeName': recipeName,
          'source': 'AI',
        };
      return _ok(200, dish);
    }
    if (method == 'DELETE') {
      (slot['dishes'] as List<dynamic>).removeWhere(
        (candidate) => (candidate as Map<String, dynamic>)['id'] == dishId,
      );
      _votes.remove(dishId);
      return _empty(204);
    }
    return _error(405, 'ERR_DEMO_METHOD', 'Phương thức này chưa được hỗ trợ trong bản demo.');
  }

  ResponseBody _routeVote({
    required String method,
    required String planId,
    required String slotId,
    required String dishId,
    required String? action,
    required Map<String, dynamic> body,
  }) {
    final plan = _plans[planId];
    final slot = plan == null ? null : _slotOf(plan, slotId);
    final dish = slot == null ? null : _dishOf(slot, dishId);
    if (dish == null) {
      return _error(404, 'ERR_DISH_NOT_FOUND', 'Không tìm thấy món để mở bình chọn.');
    }
    if (action == 'open' && method == 'POST') {
      if (_votes.containsKey(dishId)) {
        return _error(409, 'ERR_PLAN_002', 'Phiên bình chọn cho món này đang mở.');
      }
      final session = <String, dynamic>{
        'sessionId': 'demo-vote-${_voteSequence++}',
        'deadlineAt': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
        'suggestions': DemoFixtures.suggestions().map(_copyMap).toList(growable: false),
        'counts': <String, int>{},
        'myVote': null,
        'closed': false,
      };
      _votes[dishId] = session;
      dish['status'] = 'VOTING';
      return _ok(201, <String, dynamic>{
        'sessionId': session['sessionId'],
        'deadlineAt': session['deadlineAt'],
        'suggestions': session['suggestions'],
      });
    }
    final session = _votes[dishId];
    if (session == null) {
      return _error(404, 'ERR_VOTE_NOT_FOUND', 'Chưa có phiên bình chọn cho món này.');
    }
    if (action == null && method == 'POST') {
      final recipeId = body['recipeId'] as String?;
      final suggestions = session['suggestions'] as List<dynamic>;
      final exists = suggestions.any(
        (suggestion) => (suggestion as Map<String, dynamic>)['recipeId'] == recipeId,
      );
      if (recipeId == null || !exists) {
        return _error(400, 'ERR_VOTE_CANDIDATE', 'Lựa chọn món ăn không hợp lệ.');
      }
      final counts = session['counts'] as Map<String, int>;
      final oldVote = session['myVote'] as String?;
      if (oldVote != null && oldVote != recipeId && (counts[oldVote] ?? 0) > 0) {
        counts[oldVote] = counts[oldVote]! - 1;
      }
      if (oldVote != recipeId) counts[recipeId] = (counts[recipeId] ?? 0) + 1;
      session['myVote'] = recipeId;
      return _ok(200, _voteResult(session));
    }
    if (action == 'result' && method == 'GET') return _ok(200, _voteResult(session));
    if (action == 'close' && method == 'POST') {
      final winner = _winnerOf(session);
      final suggestion = (session['suggestions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((candidate) => candidate['recipeId'] == winner);
      session['closed'] = true;
      dish
        ..['status'] = 'CONFIRMED'
        ..['recipe'] = <String, dynamic>{
          'recipeId': winner,
          'recipeName': suggestion['recipeName'],
          'source': 'AI',
        };
      return _ok(200, <String, dynamic>{
        'sessionId': session['sessionId'],
        'status': 'CLOSED',
        'winnerRecipeId': winner,
      });
    }
    return _error(405, 'ERR_DEMO_METHOD', 'Phương thức này chưa được hỗ trợ trong bản demo.');
  }

  Map<String, dynamic> _voteResult(Map<String, dynamic> session) {
    final counts = session['counts'] as Map<String, int>;
    final votes = (session['suggestions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((suggestion) => <String, dynamic>{
              'recipeId': suggestion['recipeId'],
              'recipeName': suggestion['recipeName'],
              'count': counts[suggestion['recipeId']] ?? 0,
            })
        .toList(growable: false);
    return <String, dynamic>{
      'votes': votes,
      'totalMembers': 3,
      'myVote': session['myVote'],
    };
  }

  String _winnerOf(Map<String, dynamic> session) {
    final suggestions = (session['suggestions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final counts = session['counts'] as Map<String, int>;
    var winner = suggestions.first['recipeId'] as String;
    var maxVotes = -1;
    for (final suggestion in suggestions) {
      final recipeId = suggestion['recipeId'] as String;
      final count = counts[recipeId] ?? 0;
      if (count > maxVotes) {
        winner = recipeId;
        maxVotes = count;
      }
    }
    return winner;
  }

  // ── Cooking ──────────────────────────────────────────────────────

  ResponseBody _startCooking(Map<String, dynamic> body) {
    final recipeId = body['recipeId'] as String?;
    if (recipeId == null) {
      return _error(400, 'ERR_COOKING_INPUT', 'Cần chọn công thức trước khi bắt đầu nấu.');
    }
    final recipe = DemoFixtures.recipe(recipeId);
    final session = <String, dynamic>{
      'id': 'demo-cooking-${_cookingSequence++}',
      'householdId': _householdId ?? DemoFixtures.householdId,
      'recipeId': recipeId,
      'recipeName': recipe['recipeName'],
      'startedBy': _userId,
      'status': 'ACTIVE',
      'currentStep': 1,
      'totalSteps': (recipe['steps'] as List<dynamic>).length,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'endedAt': null,
    };
    _cookingSessions[session['id'] as String] = session;
    return _ok(201, session);
  }

  ResponseBody _advanceCooking(String sessionId, Map<String, dynamic> body) {
    final session = _cookingSessions[sessionId];
    if (session == null) {
      return _error(404, 'ERR_COOKING_NOT_FOUND', 'Không tìm thấy phiên nấu ăn.');
    }
    final requestedStep = (body['step'] as num?)?.toInt();
    if (requestedStep == null ||
        requestedStep < 1 ||
        requestedStep > (session['totalSteps'] as int)) {
      return _error(400, 'ERR_COOKING_STEP', 'Bước nấu ăn không hợp lệ.');
    }
    session['currentStep'] = requestedStep;
    return _ok(200, session);
  }

  ResponseBody _completeCooking(String sessionId) {
    final session = _cookingSessions[sessionId];
    if (session == null) {
      return _error(404, 'ERR_COOKING_NOT_FOUND', 'Không tìm thấy phiên nấu ăn.');
    }
    session
      ..['status'] = 'COMPLETED'
      ..['currentStep'] = session['totalSteps']
      ..['endedAt'] = DateTime.now().toUtc().toIso8601String();
    return _ok(200, _cookingResult(session));
  }

  ResponseBody _abandonCooking(String sessionId) {
    final session = _cookingSessions[sessionId];
    if (session == null) {
      return _error(404, 'ERR_COOKING_NOT_FOUND', 'Không tìm thấy phiên nấu ăn.');
    }
    session
      ..['status'] = 'ABANDONED'
      ..['endedAt'] = DateTime.now().toUtc().toIso8601String();
    return _ok(200, session);
  }

  ResponseBody _getCookingSession(String sessionId) {
    final session = _cookingSessions[sessionId];
    return session == null
        ? _error(404, 'ERR_COOKING_NOT_FOUND', 'Không tìm thấy phiên nấu ăn.')
        : _ok(200, _cookingResult(session));
  }

  Map<String, dynamic> _cookingResult(Map<String, dynamic> session) =>
      <String, dynamic>{
        'session': session,
        'ingredientDeductions': <Map<String, dynamic>>[
          <String, dynamic>{
            'ingredientName': 'Cá lóc',
            'requiredQuantity': 0.5,
            'requiredUnit': 'KG',
            'deductedQuantity': 0.5,
            'shortfallQuantity': 0.0,
            'matchedItemCount': 1,
          },
          <String, dynamic>{
            'ingredientName': 'Nước dừa',
            'requiredQuantity': 200.0,
            'requiredUnit': 'ML',
            'deductedQuantity': 0.0,
            'shortfallQuantity': 200.0,
            'matchedItemCount': 0,
          },
        ],
      };

  // ── Helpers ──────────────────────────────────────────────────────

  Map<String, dynamic>? _slotOf(Map<String, dynamic> plan, String slotId) {
    final slots = (plan['slots'] as List<dynamic>).cast<Map<String, dynamic>>();
    return slots.where((slot) => slot['id'] == slotId).firstOrNull;
  }

  Map<String, dynamic>? _dishOf(Map<String, dynamic> slot, String? dishId) {
    if (dishId == null) return null;
    final dishes = (slot['dishes'] as List<dynamic>).cast<Map<String, dynamic>>();
    return dishes.where((dish) => dish['id'] == dishId).firstOrNull;
  }

  Map<String, dynamic> _copyMap(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  bool _isExpiringSoon(String? rawDate) {
    if (rawDate == null) return false;
    final date = DateTime.tryParse(rawDate);
    return date != null && !date.isAfter(DateTime.now().add(const Duration(days: 3)));
  }

  String _currentWeekStart() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    return '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  ResponseBody? _inviteFailure(String code, {required String invalidCode}) {
    if (code == racedInviteCode || _usedInviteCodes.contains(code)) {
      return _error(400, 'ERR_HH_005', 'Mã mời này đã được sử dụng.');
    }
    if (code == expiredInviteCode || !_isKnownCode(code)) {
      return _error(400, invalidCode, 'Mã mời đã hết hạn hoặc không hợp lệ.');
    }
    return null;
  }

  bool _isKnownCode(String code) =>
      code == validInviteCode ||
      code == racedInviteCode ||
      _issuedInviteCodes.contains(code);

  String _generateInviteCode() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    // Không dùng Random: lấy timestamp để mã ổn định trong một phiên demo và
    // dễ đọc lại khi cần thử lại cùng một kịch bản.
    var seed = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(alphabet[seed % alphabet.length]);
      seed ~/= alphabet.length;
    }
    return buffer.toString();
  }

  // ── Dựng response ────────────────────────────────────────────────

  Map<String, dynamic> _sessionPayload() => <String, dynamic>{
        'accessToken': _accessToken(),
        'refreshToken': 'demo-refresh-${DateTime.now().microsecondsSinceEpoch}',
        'expiresIn': 900,
        'user': <String, dynamic>{
          'id': _userId,
          'email': _email,
          'fullName': _fullName,
          'avatarUrl': null,
        },
      };

  /// JWT không ký — chỉ phần payload là thật để `decodeJwtPayload` đọc được
  /// `household_id`/`role`/`provider` (claim giữ snake_case theo
  /// naming-convention.md §4).
  String _accessToken() {
    String encode(Map<String, dynamic> part) =>
        base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

    final header = encode(<String, dynamic>{'alg': 'none', 'typ': 'JWT'});
    final payload = encode(<String, dynamic>{
      'sub': _userId,
      'household_id': _householdId,
      'role': _role,
      'provider': _provider,
    });
    return '$header.$payload.demo-signature';
  }

  ResponseBody _ok(int status, Object? data) => _json(status, {
        'success': true,
        'data': data,
        'error': null,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

  /// `ApiResponse<Void>` — `data: null`, dùng cho `revoke`/`revoke-all`
  /// (OAS `ApiResponseEmpty`).
  ResponseBody _okEmpty(int status) => _json(status, {
        'success': true,
        'data': null,
        'error': null,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

  ResponseBody _error(int status, String code, String message) =>
      _json(status, {
        'success': false,
        'data': null,
        'error': <String, dynamic>{'code': code, 'message': message},
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  ResponseBody _empty(int status) => ResponseBody.fromString('', status);
}
