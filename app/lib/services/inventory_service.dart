import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/models.dart';

// Os dados ficam no Firestore e são compartilhados com o ERP web.
// As escritas aparecem na hora no app (cache local) e sobem para o
// servidor assim que houver internet, então as telas não esperam o commit.
class InventoryService {
  static final _db = FirebaseFirestore.instance;
  static final _categories = _db.collection('categories');
  static final _products = _db.collection('products');
  static final _movements = _db.collection('movements');
  static final _sales = _db.collection('sales');

  static Stream<List<Category>> watchCategories() => _categories
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Category.fromDoc).toList());

  static Stream<List<Product>> watchProducts() => _products
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  static Stream<List<Product>> watchProductsOf(String categoryId) => _products
      .where('categoryId', isEqualTo: categoryId)
      .snapshots()
      .map(
        (s) => s.docs.map(Product.fromDoc).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
      );

  static Stream<List<Sale>> watchSales(DateTime since) => _sales
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Sale.fromDoc).toList());

  /// Gera o código automático, ou devolve o produto que já usa o código digitado.
  static Future<String> resolveCode(String typed) async {
    final code = typed.trim().toUpperCase();
    if (code.isNotEmpty) return code;
    final all = await _products.get();
    return nextCode(all.docs.map((d) => (d.data()['code'] ?? '') as String));
  }

  static Future<Product?> productWithCode(
    String code, {
    String? exceptId,
  }) async {
    final found = await _products.where('code', isEqualTo: code).get();
    for (final doc in found.docs) {
      if (doc.id != exceptId) return Product.fromDoc(doc);
    }
    return null;
  }

  // Toda mudança de quantidade gera um registro no histórico do ERP.
  static void _addMovement(
    WriteBatch batch,
    String productId,
    String productName,
    String type,
    int delta,
  ) {
    batch.set(_movements.doc(), {
      'productId': productId,
      'productName': productName,
      'type': type,
      'delta': delta,
      'source': 'app',
      'userEmail': FirebaseAuth.instance.currentUser?.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addCategory(String name, Color color) =>
      _categories.add(Category(name: name, color: color).toMap());

  // Exclui a categoria junto com seus produtos.
  static Future<void> deleteCategory(String categoryId) async {
    final products = await _products
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final batch = _db.batch();
    for (final p in products.docs) {
      batch.delete(p.reference);
    }
    batch.delete(_categories.doc(categoryId));
    await batch.commit();
  }

  static Future<void> addProduct(Product product) {
    final batch = _db.batch();
    final ref = _products.doc();
    batch.set(ref, {
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (product.quantity > 0) {
      _addMovement(batch, ref.id, product.name, 'in', product.quantity);
    }
    return batch.commit();
  }

  static Future<void> updateProduct(
    Product product, {
    required String code,
    required String name,
    required int quantity,
    required double price,
    required String? photo,
  }) {
    final delta = quantity - product.quantity;
    final batch = _db.batch();
    batch.update(_products.doc(product.id), {
      'code': code,
      'name': name,
      'price': price,
      'photo': photo,
      if (delta != 0) 'quantity': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (delta != 0) {
      _addMovement(batch, product.id, name, 'adjust', delta);
    }
    return batch.commit();
  }

  static Future<void> deleteProduct(String productId) =>
      _products.doc(productId).delete();
}
