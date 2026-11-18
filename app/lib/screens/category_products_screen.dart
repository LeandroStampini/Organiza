import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import '../services/inventory_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ImagePicker _picker = ImagePicker();
  late final _productsStream = InventoryService.watchProductsOf(
    widget.category.id,
  );
  List<Product> _products = [];

  /// Exibe a foto do produto ou o logo quando não há foto
  Widget _buildProductImage(Product product, {double size = 50}) {
    final bytes = product.photoBytes;
    if (bytes == null) {
      return Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    return Image.memory(
      bytes,
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

  /// Exibe bottom sheet para escolher entre galeria e câmera.
  /// Retorna a foto já reduzida, pronta para salvar no Firestore.
  Future<String?> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
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
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return null;

    // Reduzida para caber com folga no documento do Firestore (limite de 1 MB)
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return 'data:${image.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
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
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Não foi possível carregar os produtos."),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _products = snapshot.data!;

          if (_products.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum produto cadastrado.\nToque em + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: _products.length,
            itemBuilder: (_, index) {
              final product = _products[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildProductImage(product, size: 50),
                ),
                title: Text(product.name),
                subtitle: Text(
                  [
                    if (product.code.isNotEmpty) "Cód. ${product.code}",
                    product.price > 0
                        ? formatMoney(product.price)
                        : "Sem preço",
                    "Qtd: ${product.quantity}",
                  ].join(" · "),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _productDialog(editProduct: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          InventoryService.deleteProduct(product.id),
                    ),
                  ],
                ),
              );
            },
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
      builder: (dialogContext) => AlertDialog(
        title: const Text("Excluir Categoria"),
        content: _products.isNotEmpty
            ? const Text(
                "Esta categoria possui produtos. Deseja excluir a categoria e todos os produtos?",
              )
            : const Text("Deseja realmente excluir a categoria?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              InventoryService.deleteCategory(widget.category.id);
              Navigator.pop(dialogContext);
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
    String? selectedPhoto = editProduct?.photo;
    String? dialogError;
    bool saving = false;
    // produto novo (ou antigo sem código) começa com o código automático ligado
    bool autoCode = (editProduct?.code ?? "").isEmpty;
    final autoCodePreview = InventoryService.resolveCode("");

    final codeController = TextEditingController(text: editProduct?.code ?? "");
    final nameController = TextEditingController(text: productName);
    final quantityController = TextEditingController(text: quantity.toString());
    final priceController = TextEditingController(
      text: priceToText(editProduct?.price ?? 0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final photoBytes = decodePhoto(selectedPhoto);
            return AlertDialog(
              title: Text(
                editProduct != null ? "Editar Produto" : "Novo Produto",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Nome do produto",
                      ),
                      controller: nameController,
                      onChanged: (value) => productName = value,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text("Gerar código automaticamente"),
                      // cores explícitas: o tema do app deixa a chave desligada branca sobre branco
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF2B4479),
                      inactiveThumbColor: Colors.grey.shade600,
                      inactiveTrackColor: Colors.grey.shade300,
                      trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? Colors.transparent
                            : Colors.grey.shade600,
                      ),
                      value: autoCode,
                      onChanged: (value) =>
                          setDialogState(() => autoCode = value),
                    ),
                    if (autoCode)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: autoCodePreview,
                          builder: (context, snap) => Text(
                            snap.hasData
                                ? "Código: ${snap.data}"
                                : "Calculando código…",
                            style: const TextStyle(
                              color: Color(0xFF2B4479),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      TextField(
                        decoration: const InputDecoration(labelText: "Código"),
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Quantidade",
                      ),
                      keyboardType: TextInputType.number,
                      controller: quantityController,
                      onChanged: (value) => quantity = int.tryParse(value) ?? 1,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Preço de venda *",
                        prefixText: "R\$ ",
                        hintText: "0,00",
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      controller: priceController,
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
                        final photo = await _pickImage();
                        if (photo != null) {
                          setDialogState(() {
                            selectedPhoto = photo;
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: photoBytes == null
                                ? Image.asset(
                                    'assets/logo.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.memory(
                                    photoBytes,
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
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final price = parsePrice(priceController.text);
                          final missing = productName.trim().isEmpty
                              ? "Informe o nome do produto"
                              : !autoCode && codeController.text.trim().isEmpty
                              ? "Digite o código ou ligue a geração automática"
                              : price <= 0
                              ? "Informe o preço de venda"
                              : null;
                          if (missing != null) {
                            setDialogState(() => dialogError = missing);
                            return;
                          }
                          setDialogState(() => saving = true);

                          // o código precisa ser único, pois é por ele que o site acha o produto na venda
                          final code = await InventoryService.resolveCode(
                            autoCode ? "" : codeController.text,
                          );
                          final owner = await InventoryService.productWithCode(
                            code,
                            exceptId: editProduct?.id,
                          );
                          if (!context.mounted) return;
                          if (owner != null) {
                            setDialogState(() {
                              saving = false;
                              dialogError =
                                  'O código $code já é do produto "${owner.name}"';
                            });
                            return;
                          }

                          final safeQuantity = quantity < 0 ? 0 : quantity;
                          // aparece na hora e sincroniza quando houver internet
                          if (editProduct != null) {
                            InventoryService.updateProduct(
                              editProduct,
                              code: code,
                              name: productName.trim(),
                              quantity: safeQuantity,
                              price: price,
                              photo: selectedPhoto,
                            );
                          } else {
                            InventoryService.addProduct(
                              Product(
                                code: code,
                                name: productName.trim(),
                                quantity: safeQuantity,
                                price: price,
                                categoryId: widget.category.id,
                                photo: selectedPhoto,
                              ),
                            );
                          }
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
