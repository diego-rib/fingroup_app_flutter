// lib/ui/auth/viewmodels/auth_viewmodel.dart
//
// Docs: "view models contain logic that converts app data into UI State;
//        expose commands (callbacks) to the view attached to event handlers;
//        a view model's state should be immutable."
//
// Um único ViewModel cobre todo o fluxo de auth para o MVP.
// Ao crescer, divida em LoginViewModel, RegisterViewModel, OtpViewModel.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/repositories/auth_repository.dart';

// ── UI State (imutável) ───────────────────────────────────────────────────────
// Docs: "use freezed or built_value to generate immutable data models."
// Para o estado de UI usamos copyWith manual para evitar geração de código
// enquanto o desenvolvedor ainda está aprendendo Freezed com as entidades de domínio.

enum AuthStatus {
  idle,
  loading,
  pendingOtp,   // OTP enviado, aguardando digitação
  success,
  failure,
}

class AuthUiState {
  const AuthUiState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.verificationId,
    this.otpDestination,  // número mascarado ou email mascarado
    this.user,
  });

  final AuthStatus status;
  final String? errorMessage;
  final String? verificationId;   // usado para verificar SMS OTP
  final String? otpDestination;   // exibido na tela OTP
  final User? user;

  bool get isLoading => status == AuthStatus.loading;
  bool get hasFailed => status == AuthStatus.failure;
  bool get isSuccess => status == AuthStatus.success;
  bool get needsOtp => status == AuthStatus.pendingOtp;

  AuthUiState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? verificationId,
    String? otpDestination,
    User? user,
  }) =>
      AuthUiState(
        status: status ?? this.status,
        errorMessage: errorMessage,          // null limpa o erro anterior
        verificationId: verificationId ?? this.verificationId,
        otpDestination: otpDestination ?? this.otpDestination,
        user: user ?? this.user,
      );
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class AuthViewModel extends StateNotifier<AuthUiState> {
  AuthViewModel(this._repo) : super(const AuthUiState());

  final AuthRepository _repo;

  // ── Commands ──────────────────────────────────────────────────────────────
  // Docs: "commands are Dart functions that allow views to execute complex
  //        logic without knowledge of its implementation."

  /// Login com Google.
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithGoogle();
    _handleResult(result);
  }

  /// Login com email e senha.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.signInWithEmail(email: email, password: password);
    _handleResult(result);
  }

  /// Cadastro com email, senha e nome.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.registerWithEmail(
        email: email, password: password, name: name);
    _handleResult(result);
  }

  /// Envia link de recuperação de senha.
  Future<void> sendPasswordReset({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.sendPasswordResetEmail(email: email);
    _handleResult(result);
  }

  /// Envia SMS OTP para o número de telefone.
  Future<void> sendPhoneOtp({required String phoneNumber}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.sendPhoneSmsOtp(phoneNumber: phoneNumber);
    _handleResult(result);
  }

  /// Envia magic link (OTP por email) — mais barato que SMS.
  Future<void> sendEmailOtp({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repo.sendEmailOtp(email: email);
    _handleResult(result);
  }

  /// Verifica o código OTP digitado pelo usuário (SMS).
  Future<void> verifySmsOtp({required String otpCode}) async {
    final vid = state.verificationId;
    if (vid == null) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Sessão expirada. Solicite um novo código.',
      );
      return;
    }
    state = state.copyWith(status: AuthStatus.loading);
    final result =
        await _repo.verifySmsOtp(verificationId: vid, otpCode: otpCode);
    _handleResult(result);
  }

  Future<void> signOut() => _repo.signOut();

  /// Limpa erro exibido — chamado quando usuário edita o campo após falha.
  void clearError() {
    if (state.hasFailed) {
      state = state.copyWith(status: AuthStatus.idle);
    }
  }

  // ── Handler interno ───────────────────────────────────────────────────────

  void _handleResult(AuthResult result) {
    switch (result) {
      case AuthSuccess(:final user):
        state = state.copyWith(status: AuthStatus.success, user: user);
      case AuthPendingVerification(:final verificationId, :final destination):
        state = state.copyWith(
          status: AuthStatus.pendingOtp,
          verificationId: verificationId,
          otpDestination: destination,
        );
      case AuthFailure(:final message, :final code):
        state = state.copyWith(
          status: AuthStatus.failure,
          errorMessage: message,
        );
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider.autoDispose<AuthViewModel, AuthUiState>(
  (ref) => AuthViewModel(ref.watch(authRepositoryProvider)),
);
