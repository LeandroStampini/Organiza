import 'package:hive/hive.dart';

class AuthService {
  static final List<Map<String, String>> users = [];

  static String? login(String user, String pass) {
    final exists = users.any(
      (u) => u['user'] == user && u['pass'] == pass,
    );

    if (!exists) return "Usuário ou senha incorretos";


    Hive.box('appBox').put('currentUser', user);

    return null; 
  }

  static String? register(String user, String pass) {
    final exists = users.any((u) => u['user'] == user);

    if (exists) return "Usuário já cadastrado";

    users.add({"user": user, "pass": pass});

    return null; 
  }

  static String? resetPassword(String user, String newpass) {
    for (var u in users) {
      if (u['user'] == user) {
        u['pass'] = newpass;
        return null;
      }
    }
    return "Usuário não encontrado";
  }

  static void logout() {
    Hive.box('appBox').delete('currentUser');
  }

  static String? currentUser() {
    return Hive.box('appBox').get('currentUser');
  }
}
