// lib/ui/auth/views/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    final notifier = ref.read(authViewModelProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.isSuccess) {
        // Após cadastro, vai para home substituindo toda a stack
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    });

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Criar conta'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crie sua conta',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preencha os dados para começar',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 28),

                  // Google
                  SocialSignInButton(
                    label: 'Cadastrar com Google',
                    iconPath: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, size: 24),
                    ),
                    onPressed: notifier.signInWithGoogle,
                    isLoading: vm.isLoading,
                  ),
                  const SizedBox(height: 20),
                  const OrDivider(),
                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _nameCtrl,
                    label: 'Nome completo',
                    hint: 'Como quer ser chamado',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) => notifier.clearError(),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'seu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) => notifier.clearError(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe o email';
                      final regex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!regex.hasMatch(v.trim())) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordCtrl,
                    label: 'Senha',
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    obscureText: _obscurePass,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => notifier.clearError(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(v)) {
                        return 'Use ao menos uma letra maiúscula';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(v)) {
                        return 'Use ao menos um número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _confirmCtrl,
                    label: 'Confirmar senha',
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    obscureText: _obscureConfirm,
                    onChanged: (_) => notifier.clearError(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) => v != _passwordCtrl.text
                        ? 'As senhas não coincidem'
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // Indicador de força da senha
                  _PasswordStrengthIndicator(password: _passwordCtrl.text),
                  const SizedBox(height: 16),

                  if (vm.hasFailed && vm.errorMessage != null) ...[
                    ErrorBanner(message: vm.errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: vm.isLoading ? null : () => _submit(notifier),
                    child: const Text('Criar conta'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Já tem conta? ',
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Entrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AuthViewModel notifier) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    notifier.registerWithEmail(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(password)) strength++;

    final labels = ['Muito fraca', 'Fraca', 'Razoável', 'Boa', 'Forte'];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow.shade700,
      Colors.lightGreen,
      Colors.green,
    ];

    final idx = (strength - 1).clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= idx
                      ? colors[idx]
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Força da senha: ${labels[idx]}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors[idx],
              ),
        ),
      ],
    );
  }
}
