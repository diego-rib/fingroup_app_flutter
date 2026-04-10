// lib/ui/auth/views/otp_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/router/app_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/widgets/auth_widgets.dart';

/// Dados passados via Navigator.pushNamed(arguments: OtpArgs(...))
class OtpArgs {
  const OtpArgs({
    required this.destination,
    required this.isPhone, // true = SMS, false = email magic link
  });

  final String destination;
  final bool isPhone;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});
  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _currentCode = '';
  bool _codeComplete = false;

  // Countdown para reenvio
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    final notifier = ref.read(authViewModelProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.isSuccess) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    });

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Ícone ─────────────────────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.args.isPhone
                        ? Icons.sms_outlined
                        : Icons.mark_email_unread_outlined,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Text('Verificação', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  widget.args.isPhone
                      ? 'Enviamos um SMS para ${widget.args.destination}'
                      : 'Acesse o link enviado para ${widget.args.destination}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 32),

                // ── Pin input ─────────────────────────────────────────────
                if (widget.args.isPhone) ...[
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 52,
                      fieldWidth: 44,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.outlineVariant,
                      selectedColor: theme.colorScheme.primary,
                      activeFillColor: theme.colorScheme.primaryContainer
                          .withOpacity(0.3),
                      inactiveFillColor: theme.colorScheme.surface,
                      selectedFillColor: theme.colorScheme.primaryContainer
                          .withOpacity(0.5),
                    ),
                    enableActiveFill: true,
                    onCompleted: (code) {
                      setState(() {
                        _currentCode = code;
                        _codeComplete = true;
                      });
                    },
                    onChanged: (code) {
                      setState(() {
                        _currentCode = code;
                        _codeComplete = code.length == 6;
                      });
                      notifier.clearError();
                    },
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  // Para email magic link, não há código para digitar —
                  // o usuário clica no link e o deep link traz de volta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Abra o email e clique no botão "Entrar no FinGroup". '
                            'Você será redirecionado automaticamente.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Erro ──────────────────────────────────────────────────
                if (vm.hasFailed && vm.errorMessage != null) ...[
                  ErrorBanner(message: vm.errorMessage!),
                  const SizedBox(height: 12),
                ],

                // ── Confirmar (apenas SMS) ────────────────────────────────
                if (widget.args.isPhone)
                  ElevatedButton(
                    onPressed: (vm.isLoading || !_codeComplete)
                        ? null
                        : () => notifier.verifySmsOtp(otpCode: _currentCode),
                    child: const Text('Verificar código'),
                  ),

                const SizedBox(height: 20),

                // ── Reenviar ──────────────────────────────────────────────
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Reenviar em ${_resendCountdown}s',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reenviar código'),
                          onPressed: () {
                            _startCountdown();
                            // Reenvia OTP — ViewModel já sabe qual método usar
                            if (widget.args.isPhone) {
                              notifier.sendPhoneOtp(
                                  phoneNumber: widget.args.destination);
                            } else {
                              notifier.sendEmailOtp(
                                  email: widget.args.destination);
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
