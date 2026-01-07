import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/dashboard_datasource.dart';
import '../../../services/api_service.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/dashboard_chart_widget.dart';
import '../../widgets/modern/modern_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardDataSource _dashboardDataSource = DashboardDataSource(ApiService());
  
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _dashboardDataSource.getStats();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar estatísticas: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/dashboard',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // Header minimalista
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Olá, Dr. Carvalho',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resumo do seu dia',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Center(
                            child: Text(
                              'DC',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Stats Cards - Grid 2x2
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStats,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    else if (_stats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total de Pacientes',
                              value: '${_stats!['totalPatients'] ?? 0}',
                              icon: Icons.people,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Consultas Hoje',
                              value: '${_stats!['consultationsToday'] ?? 0}',
                              icon: Icons.calendar_today,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Pendências',
                              value: '${_stats!['pendingConsultations'] ?? 0}',
                              icon: Icons.description,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Total Consultas',
                              value: '${_stats!['totalConsultations'] ?? 0}',
                              icon: Icons.medical_services,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Chart Section
                    // Chart Section
                    ModernCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.trending_up,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Volume de Atendimento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_stats != null && _stats!['consultationsByDay'] != null)
                            DashboardChartWidget(
                              data: (_stats!['consultationsByDay'] as List)
                                  .map<Map<String, dynamic>>((day) => {
                                    'name': (day['day'] ?? '').toString(),
                                    'total': (day['count'] ?? 0) as int,
                                  })
                                  .toList(),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Next Patients
                    // Next Patients
                    ModernCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.people,
                                    color: AppColors.accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Consultas Recentes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_stats != null && _stats!['recentConsultations'] != null)
                            ...(_stats!['recentConsultations'] as List).take(3).map((consultation) {
                              final patientName = consultation['patientName'] ?? 'Paciente Anônimo';
                              final startedAt = DateTime.parse(consultation['startedAt']);
                              final endedAt = consultation['endedAt'] != null 
                                  ? DateTime.parse(consultation['endedAt']) 
                                  : null;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PatientItem(
                                  name: patientName,
                                  lastVisit: _formatDate(startedAt),
                                  nextAppointment: _formatTime(startedAt),
                                  isFinished: endedAt != null,
                                ),
                              );
                            }).toList(),
                          if (_stats == null || (_stats!['recentConsultations'] as List).isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'Nenhuma consulta recente',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/clinical'),
                            child: const Text(
                              'Ver todas as consultas',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

class _PatientItem extends StatelessWidget {
  final String name;
  final String lastVisit;
  final String nextAppointment;
  final bool isFinished;

  const _PatientItem({
    required this.name,
    required this.lastVisit,
    required this.nextAppointment,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Última: $lastVisit',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isFinished ? AppColors.success.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFinished) ...[
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                ],
                Text(
                  nextAppointment,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFinished ? AppColors.success : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
