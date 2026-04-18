import 'package:flutter/material.dart';
import 'models.dart';

class DashboardScreen extends StatelessWidget {
  final List<Category> categories;

  const DashboardScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final allProducts = categories.expand((c) => c.products).toList();

    // total de produtos (cadastrados)
    final totalProducts = allProducts.length;

    // total de quantidade de produtos
    final totalQuantity = allProducts.fold<int>(
        0, (previousValue, product) => previousValue + product.quantity);

    // produto com maior estoque
    Product? highestStockProduct;
    Category? highestStockCategory;

    // produto com menor estoque
    Product? lowestStockProduct;
    Category? lowestStockCategory;

    if (allProducts.isNotEmpty) {
      highestStockProduct = allProducts.reduce(
        (a, b) => a.quantity > b.quantity ? a : b,
      );
      highestStockCategory =
          categories.firstWhere((c) => c.products.contains(highestStockProduct));

      lowestStockProduct = allProducts.reduce(
        (a, b) => a.quantity < b.quantity ? a : b,
      );
      lowestStockCategory =
          categories.firstWhere((c) => c.products.contains(lowestStockProduct));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Total de Categorias
            _dashCard(
              title: "Total de Categorias",
              value: categories.length.toString(),
              icon: Icons.category,
            ),

            const SizedBox(height: 16),

            // Total de Produtos cadastrados
            _dashCard(
              title: "Total de Produtos",
              value: totalProducts.toString(),
              icon: Icons.inventory,
            ),

            const SizedBox(height: 16),

            // Total de quantidade de produtos
            _dashCard(
              title: "Total de Quantidade",
              value: totalQuantity.toString(),
              icon: Icons.add_shopping_cart,
            ),

            const SizedBox(height: 16),

            // Produto com maior estoque
            if (highestStockProduct != null)
              _dashCard(
                title: "Produto com maior estoque",
                value:
                    "${highestStockProduct.name} (${highestStockProduct.quantity}) – ${highestStockCategory!.name}",
                icon: Icons.trending_up,
              ),

            const SizedBox(height: 16),

            // Produto com menor estoque
            if (lowestStockProduct != null)
              _dashCard(
                title: "Produto com menor estoque",
                value:
                    "${lowestStockProduct.name} (${lowestStockProduct.quantity}) – ${lowestStockCategory!.name}",
                icon: Icons.trending_down,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dashCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
