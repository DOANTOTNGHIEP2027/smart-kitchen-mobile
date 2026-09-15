// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SessionStore on _SessionStore, Store {
  Computed<bool>? _$isAuthenticatedComputed;

  @override
  bool get isAuthenticated =>
      (_$isAuthenticatedComputed ??= Computed<bool>(() => super.isAuthenticated,
              name: '_SessionStore.isAuthenticated'))
          .value;
  Computed<bool>? _$needsHouseholdComputed;

  @override
  bool get needsHousehold =>
      (_$needsHouseholdComputed ??= Computed<bool>(() => super.needsHousehold,
              name: '_SessionStore.needsHousehold'))
          .value;

  late final _$statusAtom =
      Atom(name: '_SessionStore.status', context: context);

  @override
  AuthStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(AuthStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$currentUserAtom =
      Atom(name: '_SessionStore.currentUser', context: context);

  @override
  UserSummary? get currentUser {
    _$currentUserAtom.reportRead();
    return super.currentUser;
  }

  @override
  set currentUser(UserSummary? value) {
    _$currentUserAtom.reportWrite(value, super.currentUser, () {
      super.currentUser = value;
    });
  }

  late final _$householdIdAtom =
      Atom(name: '_SessionStore.householdId', context: context);

  @override
  String? get householdId {
    _$householdIdAtom.reportRead();
    return super.householdId;
  }

  @override
  set householdId(String? value) {
    _$householdIdAtom.reportWrite(value, super.householdId, () {
      super.householdId = value;
    });
  }

  late final _$roleAtom = Atom(name: '_SessionStore.role', context: context);

  @override
  String? get role {
    _$roleAtom.reportRead();
    return super.role;
  }

  @override
  set role(String? value) {
    _$roleAtom.reportWrite(value, super.role, () {
      super.role = value;
    });
  }

  late final _$providerAtom =
      Atom(name: '_SessionStore.provider', context: context);

  @override
  String? get provider {
    _$providerAtom.reportRead();
    return super.provider;
  }

  @override
  set provider(String? value) {
    _$providerAtom.reportWrite(value, super.provider, () {
      super.provider = value;
    });
  }

  late final _$bootstrapAsyncAction =
      AsyncAction('_SessionStore.bootstrap', context: context);

  @override
  Future<void> bootstrap() {
    return _$bootstrapAsyncAction.run(() => super.bootstrap());
  }

  late final _$setSessionAsyncAction =
      AsyncAction('_SessionStore.setSession', context: context);

  @override
  Future<void> setSession(
      {required String accessToken,
      required String refreshToken,
      required UserSummary user}) {
    return _$setSessionAsyncAction.run(() => super.setSession(
        accessToken: accessToken, refreshToken: refreshToken, user: user));
  }

  late final _$replaceTokensAsyncAction =
      AsyncAction('_SessionStore.replaceTokens', context: context);

  @override
  Future<void> replaceTokens(
      {required String accessToken, required String refreshToken}) {
    return _$replaceTokensAsyncAction.run(() => super
        .replaceTokens(accessToken: accessToken, refreshToken: refreshToken));
  }

  late final _$refreshSessionAsyncAction =
      AsyncAction('_SessionStore.refreshSession', context: context);

  @override
  Future<void> refreshSession() {
    return _$refreshSessionAsyncAction.run(() => super.refreshSession());
  }

  late final _$clearAsyncAction =
      AsyncAction('_SessionStore.clear', context: context);

  @override
  Future<void> clear() {
    return _$clearAsyncAction.run(() => super.clear());
  }

  late final _$_SessionStoreActionController =
      ActionController(name: '_SessionStore', context: context);

  @override
  void applyHouseholdContext(
      {required String householdId, required String role}) {
    final _$actionInfo = _$_SessionStoreActionController.startAction(
        name: '_SessionStore.applyHouseholdContext');
    try {
      return super.applyHouseholdContext(householdId: householdId, role: role);
    } finally {
      _$_SessionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyRefreshedClaims(String accessToken) {
    final _$actionInfo = _$_SessionStoreActionController.startAction(
        name: '_SessionStore.applyRefreshedClaims');
    try {
      return super.applyRefreshedClaims(accessToken);
    } finally {
      _$_SessionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
currentUser: ${currentUser},
householdId: ${householdId},
role: ${role},
provider: ${provider},
isAuthenticated: ${isAuthenticated},
needsHousehold: ${needsHousehold}
    ''';
  }
}
