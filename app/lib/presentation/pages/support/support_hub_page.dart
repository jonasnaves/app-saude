import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../widgets/bottom_nav_bar.dart';

class SupportHubPage extends StatefulWidget {
  const SupportHubPage({super.key});

  @override
  State<SupportHubPage> createState() => _SupportHubPageState();
}

class _SupportHubPageState extends State<SupportHubPage> {
  String _selectedMode = 'medical';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Hub de Especialistas IA'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            label: 'IA Médica',
                            mode: 'medical',
                            icon: Icons.psychology,
                            isSelected: _selectedMode == 'medical',
                            onTap: () => setState(() => _selectedMode = 'medical'),
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            label: 'IA Jurídica',
                            mode: 'legal',
                            icon: Icons.gavel,
                            isSelected: _selectedMode == 'legal',
                            onTap: () => setState(() => _selectedMode = 'legal'),
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            label: 'IA Marketing',
                            mode: 'marketing',
                            icon: Icons.campaign,
                            isSelected: _selectedMode == 'marketing',
                            onTap: () => setState(() => _selectedMode = 'marketing'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Chat Button
                  ElevatedButton(
                    onPressed: () => context.go('/support/chat/$_selectedMode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Conversa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNavBar(currentRoute: '/support'),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String mode;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.mode,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.slateLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.slateLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

