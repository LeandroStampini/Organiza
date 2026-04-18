import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  String? errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 120,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "ORGANIZA+",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Acesse sua conta",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 30),

            buildInput("Usuário", userController, false),
            const SizedBox(height: 15),
            buildInput("Senha", passController, true),

            const SizedBox(height: 20),

            if (errorMsg != null)
              Text(
                errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  final user = userController.text.trim();
                  final pass = passController.text;

                  if (user.isEmpty || pass.isEmpty) {
                    setState(() => errorMsg = "Preencha todos os campos");
                    return;
                  }

                  final result = AuthService.login(user, pass);

                  if (result != null) {
                    setState(() => errorMsg = result);
                    return;
                  }

                  Navigator.pushReplacementNamed(context, "/home");
                },
                child: const Text(
                  "Entrar",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/forgot");
                  },
                  child: const Text(
                    "Esqueceu a senha?",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/register");
                  },
                  child: const Text(
                    "Criar conta",
                    style: TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
