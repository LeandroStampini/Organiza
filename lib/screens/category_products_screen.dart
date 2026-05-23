import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  /// Exibe a imagem correta: arquivo local ou asset padrão
  Widget _buildProductImage(String imagePath, {double size = 50}) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else {
        return Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    }
  }

  /// Exibe bottom sheet para escolher entre galeria e câmera
  Future<String?> _pickImage() async {
    String? pickedPath;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecionar imagem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                pickedPath = image?.path;
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                pickedPath = image?.path;
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return pickedPath;
  }

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
      body: widget.category.products.isEmpty
          ? const Center(
              child: Text(
                'Nenhum produto cadastrado.\nToque em + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: widget.category.products.length,
              itemBuilder: (_, index) {
                final product = widget.category.products[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildProductImage(product.imagePath, size: 50),
                  ),
                  title: Text(product.name),
                  subtitle: Text("Quantidade: ${product.quantity}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _productDialog(editProduct: product),
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
        onPressed: () => _productDialog(),
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

  void _productDialog({Product? editProduct}) {
    String productName = editProduct?.name ?? "";
    int quantity = editProduct?.quantity ?? 1;
    String selectedImagePath = editProduct?.imagePath ?? 'assets/logo.png';

    final nameController = TextEditingController(text: productName);
    final quantityController = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editProduct != null ? "Editar Produto" : "Novo Produto"),
              content: SingleChildScrollView(
                child: Column(
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Foto do produto',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final path = await _pickImage();
                        if (path != null) {
                          setDialogState(() {
                            selectedImagePath = path;
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: selectedImagePath.startsWith('assets/')
                                ? Image.asset(
                                    selectedImagePath,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(selectedImagePath),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toque para alterar',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
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
                        editProduct.imagePath = selectedImagePath;
                      } else {
                        widget.category.products.add(Product(
                          name: productName,
                          quantity: quantity,
                          imagePath: selectedImagePath,
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
      },
    );
  }
}
