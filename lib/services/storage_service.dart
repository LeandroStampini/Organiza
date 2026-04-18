import 'package:hive/hive.dart';
import '../screens/models.dart';
import 'dart:convert';

class StorageService {
  static final _box = Hive.box('appBox');

  static String _keyFor(String user) => "categories_$user";

  // BUSCAR CATEGORIAS DO USUÁRIO
  static List<Category> loadCategories(String user) {
    final raw = _box.get(_keyFor(user));
    if (raw == null) return [];

    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Category.fromMap(e)).toList();
  }

  // SALVAR CATEGORIAS DO USUÁRIO
  static void saveCategories(String user, List<Category> categories) {
    final encoded = jsonEncode(categories.map((e) => e.toMap()).toList());
    _box.put(_keyFor(user), encoded);
  }
}
