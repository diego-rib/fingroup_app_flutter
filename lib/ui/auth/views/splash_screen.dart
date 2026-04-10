// lib/ui/auth/views/splash_screen.dart
//
// Docs: "views contain only simple routing logic."
// Esta tela apenas observa o authStateProvider e navega.
// Nenhuma lógica de autenticação aqui — só roteamento.

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o stream de auth state
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          // Autenticado → vai para home (substituir a stack toda)
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        } else {
          // Não autenticado → vai para login
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — substituir por asset real
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mozis - Controle financeiro',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
