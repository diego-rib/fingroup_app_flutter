// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import '../../ui/auth/views/login_screen.dart';
import '../../ui/auth/views/register_screen.dart';
import '../../ui/auth/views/otp_screen.dart';
import '../../ui/auth/views/forgot_password_screen.dart';
import '../../ui/auth/views/splash_screen.dart';
import '../../ui/home/home_screen.dart';

abstract final class AppRouter {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp           = '/otp';
  static const home          = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      splash         => _fade(const SplashScreen()),
      login          => _slide(const LoginScreen()),
      register       => _slide(const RegisterScreen()),
      forgotPassword => _slide(const ForgotPasswordScreen()),
      otp            => _slide(OtpScreen(args: settings.arguments as OtpArgs)),
      home           => _fade(const HomeScreen()),
      _              => _fade(const SplashScreen()),
    };
  }

  static PageRouteBuilder<T> _fade<T>(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      );

  static PageRouteBuilder<T> _slide<T>(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}
