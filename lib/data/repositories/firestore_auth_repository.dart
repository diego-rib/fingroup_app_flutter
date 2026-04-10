// lib/data/repositories/firestore_auth_repository.dart
//
// Docs: "repositories handle error handling; transform raw data into domain models."
// Aqui traduzimos FirebaseAuthException → AuthResult (sealed class do domínio).
// O ViewModel nunca vê FirebaseAuthException diretamente.

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FirestoreAuthRepository implements AuthRepository {
  FirestoreAuthRepository({
    required AuthService authService,
    required FirestoreService firestore,
  })  : _auth = authService,
        _firestore = firestore;

  final AuthService _auth;
  final FirestoreService _firestore;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges;

  @override
  User? get currentUser => _auth.currentUser;

  // ── Google ────────────────────────────────────────────────────────────────
  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final credential = await _auth.signInWithGoogle();
      final user = credential.user!;
      await _ensureUserDocument(user);
      return AuthSuccess(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    } catch (e) {
      if (e.toString().contains('google-sign-in-cancelled')) {
        return const AuthFailure(message: 'Login cancelado.', code: 'cancelled');
      }
      return AuthFailure(message: 'Erro inesperado: $e');
    }
  }

  // ── Email + senha ─────────────────────────────────────────────────────────
  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailPassword(email, password);
      return AuthSuccess(user: cred.user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  @override
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailPassword(email, password);
      final user = cred.user!;
      await _auth.updateDisplayName(name);
      await _ensureUserDocument(user, name: name);
      return AuthSuccess(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordReset(email);
      return const AuthSuccess();
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  // ── SMS OTP ───────────────────────────────────────────────────────────────
  @override
  Future<AuthResult> sendPhoneSmsOtp({required String phoneNumber}) async {
    // Usamos Completer-like via variável capturada no closure
    AuthResult? result;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, _) {
        // Mascara o número para exibição: +55 (11) 9****-5678
        final masked = _maskPhone(phoneNumber);
        result = AuthPendingVerification(
          verificationId: verificationId,
          destination: masked,
        );
      },
      onFailed: (e) {
        result = AuthFailure(message: _mapFirebaseError(e), code: e.code);
      },
      onAutoVerified: (_) {
        // Android verificou automaticamente — tratado no ViewModel
        result = const AuthSuccess();
      },
    );

    // verifyPhoneNumber é assíncrono com callbacks — aguardamos até ter resultado
    // Firebase dispara onCodeSent ou onFailed quase imediatamente
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (result == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return result ??
        const AuthFailure(message: 'Tempo esgotado. Tente novamente.');
  }

  @override
  Future<AuthResult> verifySmsOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      final cred =
          await _auth.signInWithPhoneCredential(verificationId, otpCode);
      final user = cred.user!;
      await _ensureUserDocument(user);
      return AuthSuccess(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  // ── Email OTP (magic link) ────────────────────────────────────────────────
  @override
  Future<AuthResult> sendEmailOtp({required String email}) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        // TODO: substituir pela URL de deep link do seu projeto
        continueUrl: 'https://fingroup.page.link/email-login',
      );
      return AuthPendingVerification(
        verificationId: '', // email link não usa verificationId
        destination: _maskEmail(email),
      );
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  @override
  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String emailLink,
  }) async {
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        return const AuthFailure(message: 'Link inválido ou expirado.');
      }
      final cred = await _auth.signInWithEmailLink(email, emailLink);
      final user = cred.user!;
      await _ensureUserDocument(user);
      return AuthSuccess(user: user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(message: _mapFirebaseError(e), code: e.code);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() => _auth.signOut();

  // ── Helpers privados ──────────────────────────────────────────────────────

  Future<void> _ensureUserDocument(User user, {String? name}) async {
    await _firestore.createUserDocument(
      uid: user.uid,
      data: {
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName,
        'phoneNumber': user.phoneNumber,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      },
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 8) return phone;
    final start = phone.substring(0, phone.length - 6);
    final end = phone.substring(phone.length - 4);
    return '$start****$end';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    final visible = name.length > 2 ? name.substring(0, 2) : name[0];
    return '$visible***@$domain';
  }

  /// Traduz códigos de erro do Firebase em mensagens em português.
  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'Nenhuma conta encontrada com este email.',
      'wrong-password' => 'Senha incorreta.',
      'email-already-in-use' => 'Este email já está cadastrado.',
      'invalid-email' => 'Email inválido.',
      'weak-password' => 'Senha muito fraca. Use pelo menos 6 caracteres.',
      'user-disabled' => 'Esta conta foi desativada.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'invalid-verification-code' => 'Código incorreto. Verifique e tente novamente.',
      'session-expired' => 'Código expirado. Solicite um novo.',
      'invalid-phone-number' =>
        'Número de telefone inválido. Verifique o formato.',
      'quota-exceeded' => 'Limite de SMS atingido. Tente via email.',
      'network-request-failed' =>
        'Sem conexão. Verifique sua internet e tente novamente.',
      _ => e.message ?? 'Erro desconhecido. Tente novamente.',
    };
  }
}
