import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';

import 'services/auth_service.dart';

Widget _homeOrLogin() =>
    AuthService.currentUser != null ? const HomeScreen() : const LoginScreen();

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => _homeOrLogin(),
  '/register': (_) => const RegisterScreen(),
  '/forgot': (_) => const ForgotPasswordScreen(),
  '/home': (_) => _homeOrLogin(),
};
