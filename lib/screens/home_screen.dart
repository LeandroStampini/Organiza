import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'category_products_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Category> _categories = [];
  bool isGrid = true; // alternar entre grid e lista
  late Box box;

  @override
  void initState() {
    super.initState();
    // inicializar Hive
    box = Hive.box('appBox');

    // carregar categorias salvas por usuário
    final saved = box.get('categories_${widget.userId}', defaultValue: []);
    if (saved is List) {
      for (var c in saved) {
        if (c is Map) {
          _categories.add(Category.fromMap(Map<String, dynamic>.from(c)));
        }
      }
    }
  }

  void _saveCategories() {
    final listToSave = _categories.map((c) => c.toMap()).toList();
    box.put('categories_${widget.userId}', listToSave);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
        child: _categories.isEmpty
            ? const Center(child: Text("Nenhuma categoria adicionada"))
            : isGrid
                ? GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3 / 2,
                    children:
                        _categories.map((cat) => _categoryTile(cat)).toList(),
                  )
                : ListView(
                    children:
                        _categories.map((cat) => _categoryTileList(cat)).toList(),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(widget.userId),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _categoryTile(Category category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                category: category,
                onUpdate: () {
                  setState(() {});
                  _saveCategories();
                },
                onDelete: () {
                  setState(() => _categories.remove(category));
                  _saveCategories();
                },
              ),
            ),
          );
        },
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryProductsScreen(
                category: category,
                onUpdate: () {
                  setState(() {});
                  _saveCategories();
                },
                onDelete: () {
                  setState(() => _categories.remove(category));
                  _saveCategories();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------- ADICIONAR CATEGORIA ---------------------

  void _showAddCategoryDialog(String userId) {
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
              content: Column(
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (categoryName.trim().isEmpty) return;

                    setState(() {
                      _categories.add(
                        Category(
                          name: categoryName,
                          color: selectedColor,
                        ),
                      );
                      // salva categorias por usuário
                      final listToSave =
                          _categories.map((c) => c.toMap()).toList();
                      box.put('categories_$userId', listToSave);
                    });

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
      String label, double value, Color color, ValueChanged<double> onChanged) {
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
