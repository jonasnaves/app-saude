import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class DrugCatalogPage extends StatefulWidget {
  const DrugCatalogPage({super.key});

  @override
  State<DrugCatalogPage> createState() => _DrugCatalogPageState();
}

class _DrugCatalogPageState extends State<DrugCatalogPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Catálogo de Medicamentos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar princípio ativo ou marca...',
                hintStyle: const TextStyle(color: AppColors.slateLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.slateLight),
                filled: true,
                fillColor: AppColors.slate800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 0, // TODO: Carregar medicamentos da API
              itemBuilder: (context, index) {
                return Card(
                  color: AppColors.slate800.withOpacity(0.4),
                  child: ListTile(
                    title: const Text('Medicamento', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Categoria • Dosagem', style: TextStyle(color: AppColors.slateLight)),
                    trailing: IconButton(
                      icon: const Icon(Icons.shopping_cart, color: AppColors.electricBlue),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

