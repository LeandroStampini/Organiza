import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart'; 

import 'services/auth_service.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/forgot': (_) => const ForgotPasswordScreen(),


  '/home': (_) {
    final userId = AuthService.currentUser(); 

    if (userId == null || userId.isEmpty) {

      return const LoginScreen();
    }

    return HomeScreen(userId: userId);
  },
};
