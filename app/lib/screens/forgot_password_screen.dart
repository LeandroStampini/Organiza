import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  String? errorMsg;
  String? successMsg;

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Nova Senha",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enviaremos um link para o seu e-mail",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration("E-mail"),
            ),

            const SizedBox(height: 20),

            if (errorMsg != null)
              Text(errorMsg!, style: const TextStyle(color: Colors.red)),

            if (successMsg != null)
              Text(successMsg!, style: const TextStyle(color: Colors.green)),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();

                  if (email.isEmpty) {
                    setState(() => errorMsg = "Digite seu e-mail");
                    return;
                  }

                  final result = await AuthService.sendPasswordReset(email);
                  if (!context.mounted) return;

                  setState(() {
                    errorMsg = result;
                    successMsg = result == null
                        ? "Link enviado! Confira sua caixa de entrada."
                        : null;
                  });
                },
                child: const Text(
                  "Enviar link",
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
                "Voltar para o login",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
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
