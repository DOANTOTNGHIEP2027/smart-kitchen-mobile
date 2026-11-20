import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleAuth extends Mock implements GoogleSignInAuthentication {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

/// #16 / OD-38 — gateway mỏng: trả Firebase ID token, `null` CHỈ khi huỷ.
void main() {
  late _MockGoogleSignIn googleSignIn;
  late _MockFirebaseAuth firebaseAuth;
  late GoogleAuthGatewayImpl gateway;

  setUpAll(() => registerFallbackValue(_FakeAuthCredential()));

  setUp(() {
    googleSignIn = _MockGoogleSignIn();
    firebaseAuth = _MockFirebaseAuth();
    gateway = GoogleAuthGatewayImpl(
      googleSignIn: googleSignIn,
      firebaseAuth: firebaseAuth,
    );
  });

  /// Picker trả account; Firebase đăng nhập xong, user trả [firebaseIdToken].
  _MockUser stubSignedIn({String? firebaseIdToken = 'firebase-id-token'}) {
    final account = _MockGoogleAccount();
    final auth = _MockGoogleAuth();
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => auth);
    when(() => auth.accessToken).thenReturn('google-access');
    when(() => auth.idToken).thenReturn('google-id');
    when(() => firebaseAuth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => user.getIdToken()).thenAnswer((_) async => firebaseIdToken);
    return user;
  }

  group('GoogleAuthGatewayImpl.signInWithGoogle', () {
    test('thành công → trả Firebase ID token (không phải Google ID token)',
        () async {
      stubSignedIn();

      final token = await gateway.signInWithGoogle();

      expect(token, 'firebase-id-token');
      final captured = verify(() => firebaseAuth.signInWithCredential(
              captureAny())).captured.single as AuthCredential;
      expect(captured.providerId, 'google.com');
    });

    test('user huỷ picker → null, không gọi Firebase', () async {
      when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

      expect(await gateway.signInWithGoogle(), isNull);
      verifyNever(() => firebaseAuth.signInWithCredential(any()));
    });

    test('Firebase không trả ID token → signOut rồi ném lỗi, KHÔNG coi là huỷ',
        () async {
      stubSignedIn(firebaseIdToken: null);
      when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

      await expectLater(gateway.signInWithGoogle(),
          throwsA(isA<GoogleAuthTokenMissingException>()));
      verify(() => googleSignIn.signOut()).called(1);
      verify(() => firebaseAuth.signOut()).called(1);
    });

    test('ID token rỗng → ném lỗi (signOut lỗi cũng không che lỗi chính)',
        () async {
      stubSignedIn(firebaseIdToken: '');
      when(() => googleSignIn.signOut()).thenThrow(Exception('native'));

      await expectLater(gateway.signInWithGoogle(),
          throwsA(isA<GoogleAuthTokenMissingException>()));
    });

    test('Firebase mất mạng → NetworkException', () async {
      stubSignedIn();
      when(() => firebaseAuth.signInWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      await expectLater(
          gateway.signInWithGoogle(), throwsA(isA<NetworkException>()));
    });

    test('Google picker mất mạng → NetworkException', () async {
      when(() => googleSignIn.signIn())
          .thenThrow(PlatformException(code: 'network_error'));

      await expectLater(
          gateway.signInWithGoogle(), throwsA(isA<NetworkException>()));
    });

    test('sign_in_failed (thiếu SHA-1/cấu hình) → GoogleAuthUnavailable',
        () async {
      when(() => googleSignIn.signIn()).thenThrow(PlatformException(
          code: 'sign_in_failed', message: 'ApiException: 10'));

      await expectLater(gateway.signInWithGoogle(),
          throwsA(isA<GoogleAuthUnavailableException>()));
    });

    test('mã lỗi khác → giữ nguyên, không map nhầm thành mất mạng', () async {
      when(() => googleSignIn.signIn())
          .thenThrow(PlatformException(code: 'other'));
      await expectLater(
          gateway.signInWithGoogle(), throwsA(isA<PlatformException>()));

      stubSignedIn();
      when(() => firebaseAuth.signInWithCredential(any()))
          .thenThrow(FirebaseAuthException(code: 'user-disabled'));
      await expectLater(
          gateway.signInWithGoogle(), throwsA(isA<FirebaseAuthException>()));
    });
  });

  test('signOut → đăng xuất cả GoogleSignIn lẫn FirebaseAuth', () async {
    when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

    await gateway.signOut();

    verify(() => googleSignIn.signOut()).called(1);
    verify(() => firebaseAuth.signOut()).called(1);
  });

  group('UnavailableGoogleAuthGateway (Firebase chưa cấu hình)', () {
    test('signIn → GoogleAuthUnavailableException', () async {
      await expectLater(const UnavailableGoogleAuthGateway().signInWithGoogle(),
          throwsA(isA<GoogleAuthUnavailableException>()));
    });

    test('signOut → không làm gì, không ném', () async {
      await const UnavailableGoogleAuthGateway().signOut();
    });
  });
}
