import 'package:flutter/material.dart';
import 'models.dart';
import 'category_products_screen.dart';
import 'dashboard_screen.dart';
import 'ai_chat_screen.dart';
import 'sales_screen.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _categoriesStream = InventoryService.watchCategories();
  final _productsStream = InventoryService.watchProducts();
  final _todaySalesStream = InventoryService.watchSales(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  // última versão recebida do Firestore, usada pelo dashboard e pela IA
  List<Category> _categories = [];
  bool isGrid = true; // alternar entre grid e lista

  List<Category> _groupProducts(
    List<Category> categories,
    List<Product> products,
  ) {
    for (final cat in categories) {
      cat.products = products.where((p) => p.categoryId == cat.id).toList();
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await AuthService.logout();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
          },
        ),
        title: const Text(
          "Categorias",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B4479),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B4479),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _todaySalesCard(),
            const SizedBox(height: 16),
            Expanded(child: _categoriesView()),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(isGrid ? Icons.grid_view : Icons.view_list),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isGrid = !isGrid;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.point_of_sale),
                tooltip: "Vendas",
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  backgroundColor: Colors.white,
                ),
                onPressed: _openSales,
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(categories: _categories),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIChatScreen(categories: _categories),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Resumo rápido das vendas do dia (registradas pelo caixa do site).
  Widget _todaySalesCard() {
    return StreamBuilder<List<Sale>>(
      stream: _todaySalesStream,
      builder: (context, snapshot) {
        final sales = (snapshot.data ?? []).where((s) => !s.cancelled);
        final total = sales.fold(0.0, (t, s) => t + s.total);
        final count = sales.length;
        return Material(
          color: const Color(0xFF2B4479),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _openSales,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale, color: Colors.white),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vendas hoje",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          snapshot.hasData ? formatMoney(total) : "…",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    count == 1 ? "1 venda" : "$count vendas",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoriesView() {
    return StreamBuilder<List<Category>>(
      stream: _categoriesStream,
      builder: (context, catSnap) {
        return StreamBuilder<List<Product>>(
          stream: _productsStream,
          builder: (context, prodSnap) {
            if (catSnap.hasError || prodSnap.hasError) {
              return const Center(
                child: Text(
                  "Não foi possível carregar o estoque.\nVerifique sua conexão.",
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!catSnap.hasData || !prodSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            _categories = _groupProducts(catSnap.data!, prodSnap.data!);

            if (_categories.isEmpty) {
              return const Center(child: Text("Nenhuma categoria adicionada"));
            }
            return isGrid
                ? GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3 / 2,
                    children: _categories
                        .map((cat) => _categoryTile(cat))
                        .toList(),
                  )
                : ListView(
                    children: _categories
                        .map((cat) => _categoryTileList(cat))
                        .toList(),
                  );
          },
        );
      },
    );
  }

  void _openSales() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalesScreen()),
    );
  }

  void _openCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }

  Widget _categoryTile(Category category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openCategory(category),
        child: Center(
          child: Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryTileList(Category category) {
    return Card(
      color: category.color,
      child: ListTile(
        title: Text(
          category.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _openCategory(category),
      ),
    );
  }

  // --------------------- ADICIONAR CATEGORIA ---------------------

  void _showAddCategoryDialog() {
    String categoryName = "";
    double red = 0;
    double green = 122;
    double blue = 255;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Color selectedColor = Color.fromRGBO(
              red.toInt(),
              green.toInt(),
              blue.toInt(),
              1,
            );

            return AlertDialog(
              title: const Text("Nova Categoria"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Nome da categoria",
                      ),
                      onChanged: (value) => categoryName = value,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: selectedColor,
                      child: Text(
                        "Cor selecionada: R:${red.toInt()} G:${green.toInt()} B:${blue.toInt()}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _colorSlider("R", red, Colors.red, (v) {
                      setStateDialog(() => red = v);
                    }),
                    _colorSlider("G", green, Colors.green, (v) {
                      setStateDialog(() => green = v);
                    }),
                    _colorSlider("B", blue, Colors.blue, (v) {
                      setStateDialog(() => blue = v);
                    }),
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
                    if (categoryName.trim().isEmpty) return;

                    // aparece na hora e sincroniza quando houver internet
                    InventoryService.addCategory(
                      categoryName.trim(),
                      selectedColor,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Adicionar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _colorSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text(value.toInt().toString())),
      ],
    );
  }
}
