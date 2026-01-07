import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_layout.dart';

class BusinessHubPage extends StatelessWidget {
  const BusinessHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/business',
      child: SafeArea(
        child: Column(
          children: [
            // Header minimalista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: const Row(
                children: [
                  Icon(Icons.business, color: AppColors.accent, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Ecossistema de Negócios',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Credits Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CRÉDITOS DE PLATAFORMA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'R\$ 1.240,00',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                  ),
                                  child: const Text('Resgatar p/ Marketing'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  child: const Text('Ver Benefícios'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                    // Chat com IA de Negócios
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: AppColors.accent, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'IA de Negócios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Converse com nossa IA especializada em gestão de clínicas e consultórios médicos.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/support/chat/business'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Iniciar Conversa'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catálogo e Checkout Médico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/business/catalog'),
                          child: const Text('Ver catálogo'),
                        ),
                      ],
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
