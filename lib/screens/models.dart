import 'package:flutter/material.dart';

class Product {
  String name;
  int quantity;
  String imagePath;

  Product({required this.name, required this.quantity, required this.imagePath});

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'imagePath': imagePath,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        name: map['name'],
        quantity: map['quantity'],
        imagePath: map['imagePath'],
      );
}

class Category {
  String name;
  Color color;
  List<Product> products;

  Category({required this.name, required this.color, List<Product>? products})
      : products = products ?? [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color.value,
        'products': products.map((p) => p.toMap()).toList(),
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        name: map['name'],
        color: Color(map['color']),
        products: List<Product>.from(
          (map['products'] as List).map((p) => Product.fromMap(p)),
        ),
      );
}
