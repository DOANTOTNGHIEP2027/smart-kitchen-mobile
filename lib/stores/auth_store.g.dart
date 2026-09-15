// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStore, Store {
  Computed<bool>? _$isLoginLockedComputed;

  @override
  bool get isLoginLocked =>
      (_$isLoginLockedComputed ??= Computed<bool>(() => super.isLoginLocked,
              name: '_AuthStore.isLoginLocked'))
          .value;
  Computed<bool>? _$canResendOtpComputed;

  @override
  bool get canResendOtp =>
      (_$canResendOtpComputed ??= Computed<bool>(() => super.canResendOtp,
              name: '_AuthStore.canResendOtp'))
          .value;

  late final _$googleStateAtom =
      Atom(name: '_AuthStore.googleState', context: context);

  @override
  SubmissionState get googleState {
    _$googleStateAtom.reportRead();
    return super.googleState;
  }

  @override
  set googleState(SubmissionState value) {
    _$googleStateAtom.reportWrite(value, super.googleState, () {
      super.googleState = value;
    });
  }

  late final _$showAccountLinkedToastAtom =
      Atom(name: '_AuthStore.showAccountLinkedToast', context: context);

  @override
  bool get showAccountLinkedToast {
    _$showAccountLinkedToastAtom.reportRead();
    return super.showAccountLinkedToast;
  }

  @override
  set showAccountLinkedToast(bool value) {
    _$showAccountLinkedToastAtom
        .reportWrite(value, super.showAccountLinkedToast, () {
      super.showAccountLinkedToast = value;
    });
  }

  late final _$registerStateAtom =
      Atom(name: '_AuthStore.registerState', context: context);

  @override
  SubmissionState get registerState {
    _$registerStateAtom.reportRead();
    return super.registerState;
  }

  @override
  set registerState(SubmissionState value) {
    _$registerStateAtom.reportWrite(value, super.registerState, () {
      super.registerState = value;
    });
  }

  late final _$registerFieldErrorsAtom =
      Atom(name: '_AuthStore.registerFieldErrors', context: context);

  @override
  ObservableMap<String, String> get registerFieldErrors {
    _$registerFieldErrorsAtom.reportRead();
    return super.registerFieldErrors;
  }

  @override
  set registerFieldErrors(ObservableMap<String, String> value) {
    _$registerFieldErrorsAtom.reportWrite(value, super.registerFieldErrors, () {
      super.registerFieldErrors = value;
    });
  }

  late final _$otpStateAtom =
      Atom(name: '_AuthStore.otpState', context: context);

  @override
  SubmissionState get otpState {
    _$otpStateAtom.reportRead();
    return super.otpState;
  }

  @override
  set otpState(SubmissionState value) {
    _$otpStateAtom.reportWrite(value, super.otpState, () {
      super.otpState = value;
    });
  }

  late final _$resendStateAtom =
      Atom(name: '_AuthStore.resendState', context: context);

  @override
  SubmissionState get resendState {
    _$resendStateAtom.reportRead();
    return super.resendState;
  }

  @override
  set resendState(SubmissionState value) {
    _$resendStateAtom.reportWrite(value, super.resendState, () {
      super.resendState = value;
    });
  }

  late final _$pendingEmailAtom =
      Atom(name: '_AuthStore.pendingEmail', context: context);

  @override
  String? get pendingEmail {
    _$pendingEmailAtom.reportRead();
    return super.pendingEmail;
  }

  @override
  set pendingEmail(String? value) {
    _$pendingEmailAtom.reportWrite(value, super.pendingEmail, () {
      super.pendingEmail = value;
    });
  }

  late final _$otpFlowAtom = Atom(name: '_AuthStore.otpFlow', context: context);

  @override
  OtpFlow get otpFlow {
    _$otpFlowAtom.reportRead();
    return super.otpFlow;
  }

  @override
  set otpFlow(OtpFlow value) {
    _$otpFlowAtom.reportWrite(value, super.otpFlow, () {
      super.otpFlow = value;
    });
  }

  late final _$resendAvailableAtAtom =
      Atom(name: '_AuthStore.resendAvailableAt', context: context);

  @override
  DateTime? get resendAvailableAt {
    _$resendAvailableAtAtom.reportRead();
    return super.resendAvailableAt;
  }

  @override
  set resendAvailableAt(DateTime? value) {
    _$resendAvailableAtAtom.reportWrite(value, super.resendAvailableAt, () {
      super.resendAvailableAt = value;
    });
  }

  late final _$loginStateAtom =
      Atom(name: '_AuthStore.loginState', context: context);

  @override
  SubmissionState get loginState {
    _$loginStateAtom.reportRead();
    return super.loginState;
  }

  @override
  set loginState(SubmissionState value) {
    _$loginStateAtom.reportWrite(value, super.loginState, () {
      super.loginState = value;
    });
  }

  late final _$loginFieldErrorsAtom =
      Atom(name: '_AuthStore.loginFieldErrors', context: context);

  @override
  ObservableMap<String, String> get loginFieldErrors {
    _$loginFieldErrorsAtom.reportRead();
    return super.loginFieldErrors;
  }

  @override
  set loginFieldErrors(ObservableMap<String, String> value) {
    _$loginFieldErrorsAtom.reportWrite(value, super.loginFieldErrors, () {
      super.loginFieldErrors = value;
    });
  }

  late final _$loginLockedUntilAtom =
      Atom(name: '_AuthStore.loginLockedUntil', context: context);

  @override
  DateTime? get loginLockedUntil {
    _$loginLockedUntilAtom.reportRead();
    return super.loginLockedUntil;
  }

  @override
  set loginLockedUntil(DateTime? value) {
    _$loginLockedUntilAtom.reportWrite(value, super.loginLockedUntil, () {
      super.loginLockedUntil = value;
    });
  }

  late final _$upgradeStateAtom =
      Atom(name: '_AuthStore.upgradeState', context: context);

  @override
  SubmissionState get upgradeState {
    _$upgradeStateAtom.reportRead();
    return super.upgradeState;
  }

  @override
  set upgradeState(SubmissionState value) {
    _$upgradeStateAtom.reportWrite(value, super.upgradeState, () {
      super.upgradeState = value;
    });
  }

  late final _$upgradeFieldErrorsAtom =
      Atom(name: '_AuthStore.upgradeFieldErrors', context: context);

  @override
  ObservableMap<String, String> get upgradeFieldErrors {
    _$upgradeFieldErrorsAtom.reportRead();
    return super.upgradeFieldErrors;
  }

  @override
  set upgradeFieldErrors(ObservableMap<String, String> value) {
    _$upgradeFieldErrorsAtom.reportWrite(value, super.upgradeFieldErrors, () {
      super.upgradeFieldErrors = value;
    });
  }

  late final _$upgradeBannerDismissedAtom =
      Atom(name: '_AuthStore.upgradeBannerDismissed', context: context);

  @override
  bool get upgradeBannerDismissed {
    _$upgradeBannerDismissedAtom.reportRead();
    return super.upgradeBannerDismissed;
  }

  @override
  set upgradeBannerDismissed(bool value) {
    _$upgradeBannerDismissedAtom
        .reportWrite(value, super.upgradeBannerDismissed, () {
      super.upgradeBannerDismissed = value;
    });
  }

  late final _$signInWithGoogleAsyncAction =
      AsyncAction('_AuthStore.signInWithGoogle', context: context);

  @override
  Future<bool> signInWithGoogle() {
    return _$signInWithGoogleAsyncAction.run(() => super.signInWithGoogle());
  }

  late final _$registerAsyncAction =
      AsyncAction('_AuthStore.register', context: context);

  @override
  Future<bool> register(
      {required String email,
      required String password,
      required String fullName}) {
    return _$registerAsyncAction.run(() =>
        super.register(email: email, password: password, fullName: fullName));
  }

  late final _$verifyOtpAsyncAction =
      AsyncAction('_AuthStore.verifyOtp', context: context);

  @override
  Future<bool> verifyOtp(String otp) {
    return _$verifyOtpAsyncAction.run(() => super.verifyOtp(otp));
  }

  late final _$resendOtpAsyncAction =
      AsyncAction('_AuthStore.resendOtp', context: context);

  @override
  Future<void> resendOtp() {
    return _$resendOtpAsyncAction.run(() => super.resendOtp());
  }

  late final _$loginAsyncAction =
      AsyncAction('_AuthStore.login', context: context);

  @override
  Future<bool> login({required String email, required String password}) {
    return _$loginAsyncAction
        .run(() => super.login(email: email, password: password));
  }

  late final _$upgradeProfileAsyncAction =
      AsyncAction('_AuthStore.upgradeProfile', context: context);

  @override
  Future<bool> upgradeProfile(
      {required String email, required String password, String? fullName}) {
    return _$upgradeProfileAsyncAction.run(() => super
        .upgradeProfile(email: email, password: password, fullName: fullName));
  }

  late final _$_AuthStoreActionController =
      ActionController(name: '_AuthStore', context: context);

  @override
  void consumeAccountLinkedToast() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
        name: '_AuthStore.consumeAccountLinkedToast');
    try {
      return super.consumeAccountLinkedToast();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetGoogleState() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
        name: '_AuthStore.resetGoogleState');
    try {
      return super.resetGoogleState();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void prepareOtp({required String email, required OtpFlow flow}) {
    final _$actionInfo =
        _$_AuthStoreActionController.startAction(name: '_AuthStore.prepareOtp');
    try {
      return super.prepareOtp(email: email, flow: flow);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearLoginLock() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
        name: '_AuthStore.clearLoginLock');
    try {
      return super.clearLoginLock();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void dismissUpgradeBanner() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
        name: '_AuthStore.dismissUpgradeBanner');
    try {
      return super.dismissUpgradeBanner();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo =
        _$_AuthStoreActionController.startAction(name: '_AuthStore.reset');
    try {
      return super.reset();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
googleState: ${googleState},
showAccountLinkedToast: ${showAccountLinkedToast},
registerState: ${registerState},
registerFieldErrors: ${registerFieldErrors},
otpState: ${otpState},
resendState: ${resendState},
pendingEmail: ${pendingEmail},
otpFlow: ${otpFlow},
resendAvailableAt: ${resendAvailableAt},
loginState: ${loginState},
loginFieldErrors: ${loginFieldErrors},
loginLockedUntil: ${loginLockedUntil},
upgradeState: ${upgradeState},
upgradeFieldErrors: ${upgradeFieldErrors},
upgradeBannerDismissed: ${upgradeBannerDismissed},
isLoginLocked: ${isLoginLocked},
canResendOtp: ${canResendOtp}
    ''';
  }
}
