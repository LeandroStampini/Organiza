import 'package:firebase_auth/firebase_auth.dart';

// Mesmo login do ERP web (Firebase Authentication com e-mail e senha).
class AuthService {
  static final _auth = FirebaseAuth.instance;

  static String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return "E-mail inválido";
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return "E-mail ou senha incorretos";
      case 'email-already-in-use':
        return "E-mail já cadastrado";
      case 'weak-password':
        return "A senha precisa ter pelo menos 6 caracteres";
      case 'too-many-requests':
        return "Muitas tentativas. Aguarde um pouco e tente de novo";
      case 'network-request-failed':
        return "Sem conexão com a internet";
      default:
        return "Não foi possível concluir. Tente novamente";
    }
  }

  static Future<String?> login(String email, String pass) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: pass);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    }
  }

  static Future<String?> register(String email, String pass) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: pass);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    }
  }

  static Future<void> logout() => _auth.signOut();

  static User? get currentUser => _auth.currentUser;
}
