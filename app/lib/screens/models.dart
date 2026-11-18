import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Mesma estrutura usada pelo ERP web (erp/src/types.ts).

class Product {
  final String id;
  String code; // código do produto, usado para vender pelo caixa do site
  String name;
  int quantity;
  int minStock;
  double price; // preço de venda em reais
  String categoryId;
  String? photo; // data URL JPEG comprimida

  Product({
    this.id = '',
    this.code = '',
    required this.name,
    required this.quantity,
    required this.categoryId,
    this.minStock = 0,
    this.price = 0,
    this.photo,
  });

  // Decodificada uma vez só, para a imagem não piscar a cada atualização.
  late final Uint8List? photoBytes = decodePhoto(photo);

  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'quantity': quantity,
    'minStock': minStock,
    'price': price,
    'categoryId': categoryId,
    'photo': photo,
  };

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Product(
      id: doc.id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      minStock: (map['minStock'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      categoryId: map['categoryId'] ?? '',
      photo: map['photo'],
    );
  }
}

class Category {
  final String id;
  String name;
  Color color;
  List<Product> products;

  Category({
    this.id = '',
    required this.name,
    required this.color,
    List<Product>? products,
  }) : products = products ?? [];

  Map<String, dynamic> toMap() => {'name': name, 'color': colorToHex(color)};

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: map['name'] ?? '',
      color: colorFromHex(map['color'] ?? '#2B4479'),
    );
  }
}

// Vendas são registradas pelo caixa do site; o app só acompanha.
class SaleItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  SaleItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
    productId: map['productId'] ?? '',
    name: map['name'] ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    price: (map['price'] as num?)?.toDouble() ?? 0,
  );
}

class Sale {
  final String id;
  final List<SaleItem> items;
  final double total;
  final String payment; // dinheiro | pix | cartao
  final bool cancelled;
  final DateTime? createdAt;

  Sale({
    required this.id,
    required this.items,
    required this.total,
    required this.payment,
    required this.cancelled,
    required this.createdAt,
  });

  static const paymentLabels = {
    'dinheiro': 'Dinheiro',
    'pix': 'Pix',
    'cartao': 'Cartão',
  };

  String get paymentLabel => paymentLabels[payment] ?? payment;

  int get itemCount => items.fold(0, (n, i) => n + i.quantity);

  factory Sale.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Sale(
      id: doc.id,
      items: ((map['items'] as List?) ?? [])
          .map((i) => SaleItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      payment: map['payment'] ?? '',
      cancelled: map['status'] == 'cancelled',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// R$ 1.234,56
String formatMoney(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}R\$ $buffer,${parts[1]}';
}

/// Lê valores digitados como "12,50", "12.50" ou "1.234,56" (mesma regra do site).
double parsePrice(String text) {
  final cleaned = text
      .replaceAll(RegExp(r'[^\d,.]'), '')
      .replaceAll(RegExp(r'\.(?=\d{3}(\D|$))'), '')
      .replaceAll(',', '.');
  final value = double.tryParse(cleaned) ?? 0;
  return value > 0 ? (value * 100).round() / 100 : 0;
}

/// "12,50" para preencher o campo de preço (vazio quando não há preço).
String priceToText(double price) =>
    price > 0 ? price.toStringAsFixed(2).replaceAll('.', ',') : '';

/// Próximo código sequencial (0001, 0002…). Códigos de barras longos não entram na conta.
String nextCode(Iterable<String> codes) {
  final numeric = RegExp(r'^\d{1,6}$');
  final max = codes
      .where(numeric.hasMatch)
      .map(int.parse)
      .fold<int>(0, (m, c) => c > m ? c : m);
  return (max + 1).toString().padLeft(4, '0');
}

Color colorFromHex(String hex) =>
    Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);

String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Uint8List? decodePhoto(String? photo) {
  if (photo == null || photo.isEmpty) return null;
  try {
    return base64Decode(photo.substring(photo.indexOf(',') + 1));
  } catch (_) {
    return null;
  }
}
