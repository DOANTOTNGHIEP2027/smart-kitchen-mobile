// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HouseholdStore on _HouseholdStore, Store {
  Computed<JoinRoute>? _$joinRouteComputed;

  @override
  JoinRoute get joinRoute =>
      (_$joinRouteComputed ??= Computed<JoinRoute>(() => super.joinRoute,
              name: '_HouseholdStore.joinRoute'))
          .value;
  Computed<bool>? _$asksForDisplayNameComputed;

  @override
  bool get asksForDisplayName => (_$asksForDisplayNameComputed ??=
          Computed<bool>(() => super.asksForDisplayName,
              name: '_HouseholdStore.asksForDisplayName'))
      .value;

  late final _$createStateAtom =
      Atom(name: '_HouseholdStore.createState', context: context);

  @override
  SubmissionState get createState {
    _$createStateAtom.reportRead();
    return super.createState;
  }

  @override
  set createState(SubmissionState value) {
    _$createStateAtom.reportWrite(value, super.createState, () {
      super.createState = value;
    });
  }

  late final _$createNameErrorAtom =
      Atom(name: '_HouseholdStore.createNameError', context: context);

  @override
  String? get createNameError {
    _$createNameErrorAtom.reportRead();
    return super.createNameError;
  }

  @override
  set createNameError(String? value) {
    _$createNameErrorAtom.reportWrite(value, super.createNameError, () {
      super.createNameError = value;
    });
  }

  late final _$createdHouseholdAtom =
      Atom(name: '_HouseholdStore.createdHousehold', context: context);

  @override
  HouseholdCreated? get createdHousehold {
    _$createdHouseholdAtom.reportRead();
    return super.createdHousehold;
  }

  @override
  set createdHousehold(HouseholdCreated? value) {
    _$createdHouseholdAtom.reportWrite(value, super.createdHousehold, () {
      super.createdHousehold = value;
    });
  }

  late final _$previewStateAtom =
      Atom(name: '_HouseholdStore.previewState', context: context);

  @override
  SubmissionState get previewState {
    _$previewStateAtom.reportRead();
    return super.previewState;
  }

  @override
  set previewState(SubmissionState value) {
    _$previewStateAtom.reportWrite(value, super.previewState, () {
      super.previewState = value;
    });
  }

  late final _$previewAtom =
      Atom(name: '_HouseholdStore.preview', context: context);

  @override
  InvitePreview? get preview {
    _$previewAtom.reportRead();
    return super.preview;
  }

  @override
  set preview(InvitePreview? value) {
    _$previewAtom.reportWrite(value, super.preview, () {
      super.preview = value;
    });
  }

  late final _$pendingCodeAtom =
      Atom(name: '_HouseholdStore.pendingCode', context: context);

  @override
  String? get pendingCode {
    _$pendingCodeAtom.reportRead();
    return super.pendingCode;
  }

  @override
  set pendingCode(String? value) {
    _$pendingCodeAtom.reportWrite(value, super.pendingCode, () {
      super.pendingCode = value;
    });
  }

  late final _$joinStateAtom =
      Atom(name: '_HouseholdStore.joinState', context: context);

  @override
  SubmissionState get joinState {
    _$joinStateAtom.reportRead();
    return super.joinState;
  }

  @override
  set joinState(SubmissionState value) {
    _$joinStateAtom.reportWrite(value, super.joinState, () {
      super.joinState = value;
    });
  }

  late final _$requiresProfileCompletionAtom =
      Atom(name: '_HouseholdStore.requiresProfileCompletion', context: context);

  @override
  bool get requiresProfileCompletion {
    _$requiresProfileCompletionAtom.reportRead();
    return super.requiresProfileCompletion;
  }

  @override
  set requiresProfileCompletion(bool value) {
    _$requiresProfileCompletionAtom
        .reportWrite(value, super.requiresProfileCompletion, () {
      super.requiresProfileCompletion = value;
    });
  }

  late final _$createHouseholdAsyncAction =
      AsyncAction('_HouseholdStore.createHousehold', context: context);

  @override
  Future<bool> createHousehold(String name) {
    return _$createHouseholdAsyncAction.run(() => super.createHousehold(name));
  }

  late final _$loadPreviewAsyncAction =
      AsyncAction('_HouseholdStore.loadPreview', context: context);

  @override
  Future<bool> loadPreview(String code) {
    return _$loadPreviewAsyncAction.run(() => super.loadPreview(code));
  }

  late final _$confirmJoinAsyncAction =
      AsyncAction('_HouseholdStore.confirmJoin', context: context);

  @override
  Future<bool> confirmJoin({String? displayName}) {
    return _$confirmJoinAsyncAction
        .run(() => super.confirmJoin(displayName: displayName));
  }

  late final _$_HouseholdStoreActionController =
      ActionController(name: '_HouseholdStore', context: context);

  @override
  void resetJoin() {
    final _$actionInfo = _$_HouseholdStoreActionController.startAction(
        name: '_HouseholdStore.resetJoin');
    try {
      return super.resetJoin();
    } finally {
      _$_HouseholdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo = _$_HouseholdStoreActionController.startAction(
        name: '_HouseholdStore.reset');
    try {
      return super.reset();
    } finally {
      _$_HouseholdStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
createState: ${createState},
createNameError: ${createNameError},
createdHousehold: ${createdHousehold},
previewState: ${previewState},
preview: ${preview},
pendingCode: ${pendingCode},
joinState: ${joinState},
requiresProfileCompletion: ${requiresProfileCompletion},
joinRoute: ${joinRoute},
asksForDisplayName: ${asksForDisplayName}
    ''';
  }
}
