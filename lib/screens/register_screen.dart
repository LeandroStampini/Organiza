import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();
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

            Image.asset("assets/logo.png", height: 120),

            const SizedBox(height: 10),

            const Text(
              "ORGANIZA+",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Criar a conta",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            buildInput("Usuário", userController, false),
            const SizedBox(height: 15),
            buildInput("Senha", passController, true),
            const SizedBox(height: 15),
            buildInput("Confirme a senha", confirmController, true),

            const SizedBox(height: 20),

            if (errorMsg != null)
              Text(errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                ),
                onPressed: () {
                  final user = userController.text.trim();
                  final pass = passController.text;
                  final confirm = confirmController.text;

                  if (user.isEmpty || pass.isEmpty || confirm.isEmpty) {
                    setState(() => errorMsg = "Preencha todos os campos");
                    return;
                  }

                  if (pass != confirm) {
                    setState(() => errorMsg = "As senhas não coincidem");
                    return;
                  }

                  final result = AuthService.register(user, pass);

                  if (result != null) {
                    setState(() => errorMsg = result);
                    return;
                  }

                  Navigator.pop(context);
                },
                child: const Text(
                  "Cadastrar",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Já possui um cadastro?",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController c, bool pwd) {
    return TextField(
      controller: c,
      obscureText: pwd,
      decoration: inputDecoration(label),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
