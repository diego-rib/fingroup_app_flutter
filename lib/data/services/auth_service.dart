// lib/data/services/auth_service.dart
//
// Docs: "services wrap API endpoints; hold NO state; expose Future/Stream objects."
// Esta classe só conhece Firebase — nada de domínio aqui.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Google ────────────────────────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('google-sign-in-cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ── Email + senha ─────────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmailPassword(
          String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createUserWithEmailPassword(
          String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updateDisplayName(String name) =>
      _auth.currentUser!.updateDisplayName(name);

  // ── Telefone / SMS OTP ────────────────────────────────────────────────────
  // Firebase cuida do envio do SMS. O fluxo tem dois callbacks:
  //   onCodeSent      → temos o verificationId, podemos mostrar tela OTP
  //   onAutoVerified  → Android verificou automaticamente (sem digitar)
  //   onFailed        → algo errado (número inválido, cota excedida etc.)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(PhoneAuthCredential) onAutoVerified,
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
      String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  // ── Email link (magic link / passwordless) ────────────────────────────────
  // Mais barato que SMS: nenhum custo adicional no Firebase.
  // O link contém um token único que autentica o usuário ao clicar.
  //
  // Configuração necessária:
  //   1. Habilitar "Email link" em Firebase Console → Authentication → Sign-in methods
  //   2. Adicionar o deep link domain nos Dynamic Links ou App Links do projeto
  //   3. Configurar android/ios com o continueUrl correto
  Future<void> sendSignInLinkToEmail({
    required String email,
    required String continueUrl,
  }) {
    final actionCodeSettings = ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.fingroup.app', // ajuste para seu bundle ID
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.fingroup.app',
    );
    return _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  bool isSignInWithEmailLink(String emailLink) =>
      _auth.isSignInWithEmailLink(emailLink);

  Future<UserCredential> signInWithEmailLink(
          String email, String emailLink) =>
      _auth.signInWithEmailLink(email: email, emailLink: emailLink);

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
