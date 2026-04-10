// lib/ui/auth/views/login_screen.dart
//
// Docs: "views are the primary method of rendering UI and shouldn't contain
//        any business logic; they should be passed all data needed from the VM."
// Lógica de autenticação → AuthViewModel. Esta View só renderiza e chama commands.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  // Controla qual tab está ativa: email/senha ou telefone
  int _tabIndex = 0;
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);
    final notifier = ref.read(authViewModelProvider.notifier);
    final theme = Theme.of(context);

    // Docs: "view reacts to state changes" — navega quando sucesso ou OTP pendente
    ref.listen(authViewModelProvider, (_, next) {
      if (next.isSuccess) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
      if (next.needsOtp) {
        Navigator.of(context).pushNamed(
          AppRouter.otp,
          arguments: OtpArgs(
            destination: next.otpDestination ?? '',
            isPhone: _tabIndex == 1,
          ),
        );
      }
    });

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ── Cabeçalho ────────────────────────────────────────────
                  Text('Bem-vindo de volta',
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Entre na sua conta para continuar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Google Sign-In ────────────────────────────────────────
                  SocialSignInButton(
                    label: 'Continuar com Google',
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
                  const SizedBox(height: 24),
                  const OrDivider(),
                  const SizedBox(height: 24),

                  // ── Tabs: Email | Telefone ────────────────────────────────
                  _buildTabBar(theme),
                  const SizedBox(height: 20),

                  // ── Campos conforme tab ───────────────────────────────────
                  if (_tabIndex == 0) ...[
                    AuthTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onChanged: (_) => notifier.clearError(),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passwordCtrl,
                      label: 'Senha',
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      onChanged: (_) => notifier.clearError(),
                      onFieldSubmitted: (_) => _submitEmailLogin(notifier),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRouter.forgotPassword),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                  ] else ...[
                    _PhoneField(controller: _phoneCtrl),
                    const SizedBox(height: 8),
                    Text(
                      'Enviaremos um código SMS para verificar seu número.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ── Banner de erro ────────────────────────────────────────
                  if (vm.hasFailed && vm.errorMessage != null) ...[
                    ErrorBanner(message: vm.errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  // ── Botão principal ───────────────────────────────────────
                  ElevatedButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => _tabIndex == 0
                            ? _submitEmailLogin(notifier)
                            : _submitPhoneLogin(notifier),
                    child: Text(
                        _tabIndex == 0 ? 'Entrar' : 'Enviar código SMS'),
                  ),
                  const SizedBox(height: 24),

                  // ── Link para cadastro ────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Não tem conta? ',
                            style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRouter.register),
                          child: const Text('Criar conta'),
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

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Email',
            icon: Icons.email_outlined,
            selected: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _TabItem(
            label: 'Telefone',
            icon: Icons.phone_outlined,
            selected: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  void _submitEmailLogin(AuthViewModel notifier) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    notifier.signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
  }

  void _submitPhoneLogin(AuthViewModel notifier) {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    notifier.sendPhoneOtp(phoneNumber: phone);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Informe o email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }
}

// ── Sub-widgets privados (lean, sem lógica) ───────────────────────────────────

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatefulWidget {
  const _PhoneField({required this.controller});
  final TextEditingController controller;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  String _countryCode = '+55';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor de código de país simples para o MVP
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            initialValue: _countryCode,
            onSelected: (v) {
              setState(() => _countryCode = v);
              // atualiza o controller com o novo código
              final number = widget.controller.text
                  .replaceFirst(RegExp(r'^\+\d+\s?'), '');
              widget.controller.text = '$v $number';
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: '+55', child: Text('🇧🇷 +55')),
              const PopupMenuItem(value: '+1', child: Text('🇺🇸 +1')),
              const PopupMenuItem(value: '+351', child: Text('🇵🇹 +351')),
              const PopupMenuItem(value: '+244', child: Text('🇦🇴 +244')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(_countryCode,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Número',
              hintText: '(11) 99999-9999',
            ),
            onChanged: (v) {
              // Garante que o número começa com o código do país
              if (!v.startsWith('+')) {
                widget.controller.value = TextEditingValue(
                  text: '$_countryCode $v',
                  selection: TextSelection.collapsed(
                      offset: '$_countryCode $v'.length),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
