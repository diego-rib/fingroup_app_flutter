// lib/domain/repositories/auth_repository.dart
//
// Interface abstrata. ViewModels dependem DESTA interface, nunca da implementação.
// Permite trocar implementação (ex: mock para testes) sem mudar ViewModels.

import 'package:firebase_auth/firebase_auth.dart';

/// Resultado de operações de autenticação.
/// Evitamos lançar exceções diretamente para o ViewModel —
/// retornamos Either-like sealed class para forçar tratamento explícito.
sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess({this.user});
  final User? user;
}

final class AuthFailure extends AuthResult {
  const AuthFailure({required this.message, this.code});
  final String message;
  final String? code; // ex: 'invalid-phone-number', 'too-many-requests'
}

/// Pendente de verificação OTP (email ou SMS).
final class AuthPendingVerification extends AuthResult {
  const AuthPendingVerification({
    required this.verificationId,
    required this.destination, // ex: email ou número mascarado
  });
  final String verificationId;
  final String destination;
}

// ─────────────────────────────────────────────────────────────────────────────

abstract class AuthRepository {
  /// Stream do usuário autenticado atual.
  Stream<User?> get authStateChanges;

  User? get currentUser;

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<AuthResult> signInWithGoogle();

  // ── Email + senha ─────────────────────────────────────────────────────────
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<AuthResult> sendPasswordResetEmail({required String email});

  // ── Telefone (SMS OTP via Firebase) ───────────────────────────────────────
  // ⚠️ AVISO DE CUSTO:
  // Firebase Phone Auth cobra por verificação de SMS enviada.
  // Em produção, considere implementar rate limiting no Cloud Functions
  // para evitar abuso e custos inesperados.
  // Plano Spark (gratuito): 10 verificações/dia. Plano Blaze: por uso.
  Future<AuthResult> sendPhoneSmsOtp({required String phoneNumber});

  Future<AuthResult> verifySmsOtp({
    required String verificationId,
    required String otpCode,
  });

  // ── Email OTP (link mágico) ───────────────────────────────────────────────
  // Mais barato que SMS e sem custo extra no Firebase.
  // O usuário recebe um link no email e é redirecionado de volta ao app.
  Future<AuthResult> sendEmailOtp({required String email});

  Future<AuthResult> verifyEmailOtp({
    required String email,
    required String emailLink,
  });

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut();
}
