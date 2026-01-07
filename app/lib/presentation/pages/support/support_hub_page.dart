import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_layout.dart';

class SupportHubPage extends StatefulWidget {
  const SupportHubPage({super.key});

  @override
  State<SupportHubPage> createState() => _SupportHubPageState();
}

class _SupportHubPageState extends State<SupportHubPage> {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/support',
      child: SafeArea(
        child: Column(
          children: [
            // Header minimalista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: const Row(
                children: [
                  Text(
                    'Hub de Especialistas IA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.75,
                  children: [
                    _AICard(
                      label: 'IA Médica',
                      mode: 'medical',
                      icon: Icons.psychology,
                      color: Colors.blue,
                    ),
                    _AICard(
                      label: 'IA Jurídica',
                      mode: 'legal',
                      icon: Icons.gavel,
                      color: Colors.green,
                    ),
                    _AICard(
                      label: 'IA Marketing',
                      mode: 'marketing',
                      icon: Icons.campaign,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AICard extends StatelessWidget {
  final String label;
  final String mode;
  final IconData icon;
  final Color color;

  const _AICard({
    required this.label,
    required this.mode,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/support/chat/$mode'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 40,
            ),
          ).animate().scale(
                duration: 200.ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}
