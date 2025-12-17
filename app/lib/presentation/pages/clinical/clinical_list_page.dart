import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/floating_action_button.dart';

class ClinicalListPage extends StatelessWidget {
  const ClinicalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Consultas Clínicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/clinical/recording'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 0, // TODO: Carregar consultas da API
              itemBuilder: (context, index) {
                return Card(
                  color: AppColors.slate800.withOpacity(0.5),
                  child: ListTile(
                    title: const Text('Consulta', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Data', style: TextStyle(color: AppColors.slateLight)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slateLight),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
          BottomNavBar(currentRoute: '/clinical'),
        ],
      ),
      floatingActionButton: const RecordingFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

