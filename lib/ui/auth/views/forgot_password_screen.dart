// lib/ui/auth/views/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../../core/widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    final notifier = ref.read(authViewModelProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.isSuccess && !_sent) {
        setState(() => _sent = true);
      }
    });

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Recuperar senha'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _sent ? _buildSuccessState(context) : _buildForm(vm, notifier, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AuthUiState vm, AuthViewModel notifier, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.lock_reset_rounded,
                size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Esqueceu a senha?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Informe seu email e enviaremos um link para você criar uma nova senha.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 28),
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => notifier.clearError(),
            onFieldSubmitted: (_) => _submit(notifier),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe o email';
              final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!regex.hasMatch(v.trim())) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (vm.hasFailed && vm.errorMessage != null) ...[
            ErrorBanner(message: vm.errorMessage!),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: vm.isLoading ? null : () => _submit(notifier),
            child: const Text('Enviar link de recuperação'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text('Email enviado!', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          'Verifique sua caixa de entrada em ${_emailCtrl.text.trim()} '
          'e siga as instruções para redefinir sua senha.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar para o login'),
        ),
      ],
    );
  }

  void _submit(AuthViewModel notifier) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    notifier.sendPasswordReset(email: _emailCtrl.text.trim());
  }
}
