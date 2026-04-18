import 'package:flutter/material.dart';
import 'models.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteCategory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.category.products.length,
        itemBuilder: (_, index) {
          final product = widget.category.products[index];
          return ListTile(
            leading: Image.asset(
              product.imagePath,
              width: 50,
              height: 50,
            ),
            title: Text(product.name),
            subtitle: Text("Quantidade: ${product.quantity}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editProductDialog(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      widget.category.products.removeAt(index);
                    });
                    widget.onUpdate();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteCategory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir Categoria"),
        content: widget.category.products.isNotEmpty
            ? const Text(
                "Esta categoria possui produtos. Deseja excluir a categoria e todos os produtos?")
            : const Text("Deseja realmente excluir a categoria?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDelete(); 
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    _productDialog();
  }

  void _editProductDialog(Product product) {
    _productDialog(editProduct: product);
  }

  void _productDialog({Product? editProduct}) {
    String productName = editProduct?.name ?? "";
    int quantity = editProduct?.quantity ?? 1;

    final nameController = TextEditingController(text: productName);
    final quantityController =
        TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editProduct != null ? "Editar Produto" : "Novo Produto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nome do produto"),
                controller: nameController,
                onChanged: (value) => productName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Quantidade"),
                keyboardType: TextInputType.number,
                controller: quantityController,
                onChanged: (value) => quantity = int.tryParse(value) ?? 1,
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/logo.png',
                width: 100,
                height: 100,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (productName.trim().isEmpty) return;
                setState(() {
                  if (editProduct != null) {
                    editProduct.name = productName;
                    editProduct.quantity = quantity;
                  } else {
                    widget.category.products.add(Product(
                      name: productName,
                      quantity: quantity,
                      imagePath: 'assets/logo.png',
                    ));
                  }
                });
                widget.onUpdate();
                Navigator.pop(context);
              },
              child: Text(editProduct != null ? "Salvar" : "Adicionar"),
            ),
          ],
        );
      },
    );
  }
}
