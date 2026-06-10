import 'package:hive/hive.dart';
import 'dart:convert';

class AuthService {
  static const _usersKey = 'registered_users';

  static List<Map<String, String>> _loadUsers() {
    final raw = Hive.box('appBox').get(_usersKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  static void _saveUsers(List<Map<String, String>> users) {
    Hive.box('appBox').put(_usersKey, jsonEncode(users));
  }

  static String? login(String user, String pass) {
    final users = _loadUsers();
    final exists = users.any(
      (u) => u['user'] == user && u['pass'] == pass,
    );

    if (!exists) return "Usuário ou senha incorretos";

    Hive.box('appBox').put('currentUser', user);
    return null;
  }

  static String? register(String user, String pass) {
    final users = _loadUsers();
    final exists = users.any((u) => u['user'] == user);

    if (exists) return "Usuário já cadastrado";

    users.add({"user": user, "pass": pass});
    _saveUsers(users);
    return null;
  }

  static String? resetPassword(String user, String newpass) {
    final users = _loadUsers();
    for (var u in users) {
      if (u['user'] == user) {
        u['pass'] = newpass;
        _saveUsers(users);
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
