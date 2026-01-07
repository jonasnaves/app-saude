import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/clinical_datasource.dart';
import '../../../data/models/consultation_model.dart';
import '../../../services/api_service.dart';
import '../../widgets/app_layout.dart';

class ClinicalListPage extends StatefulWidget {
  const ClinicalListPage({super.key});

  @override
  State<ClinicalListPage> createState() => _ClinicalListPageState();
}

class _ClinicalListPageState extends State<ClinicalListPage> {
  final ClinicalDataSource _clinicalDataSource = ClinicalDataSource(ApiService());
  
  List<ConsultationModel> _consultations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      print('[ClinicalListPage] Carregando consultas...');
      final consultations = await _clinicalDataSource.getConsultations();
      print('[ClinicalListPage] Consultas carregadas: ${consultations.length}');
      
      if (mounted) {
        setState(() {
          _consultations = consultations;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[ClinicalListPage] Erro ao carregar consultas: $e');
      print('[ClinicalListPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar consultas: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/clinical',
      child: SafeArea(
        child: Column(
          children: [
            // Header minimalista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Consultas Clínicas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 24),
                    color: AppColors.textSecondary,
                    onPressed: _loadConsultations,
                    tooltip: 'Atualizar',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    color: AppColors.primary,
                    onPressed: () => context.go('/clinical/recording'),
                    tooltip: 'Nova consulta',
                  ),
                ],
              ),
            ),
            // Lista de consultas
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadConsultations,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : _consultations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_information_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma consulta encontrada',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Clique no botão + para criar uma nova consulta',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadConsultations,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                itemCount: _consultations.length,
                                itemBuilder: (context, index) {
                                  final consultation = _consultations[index];
                                  return _ConsultationCard(
                                    consultation: consultation,
                                    onTap: () => context.go('/clinical/${consultation.id}'),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback onTap;

  const _ConsultationCard({
    super.key,
    required this.consultation,
    required this.onTap,
  });

  String _formatDate(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      final hourStr = dateTime.hour.toString().padLeft(2, '0');
      final minuteStr = dateTime.minute.toString().padLeft(2, '0');
      
      if (difference.inDays == 0) {
        return 'Hoje às $hourStr:$minuteStr';
      } else if (difference.inDays == 1) {
        return 'Ontem às $hourStr:$minuteStr';
      } else if (difference.inDays < 7) {
        // Usar formato simples sem locale para evitar erro
        final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
        final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        // weekday retorna 1-7 (segunda=1, domingo=7), ajustar para array 0-6
        final weekdayIndex = dateTime.weekday == 7 ? 0 : dateTime.weekday;
        return '${weekdays[weekdayIndex]}, ${dateTime.day} ${months[dateTime.month - 1]}';
      } else {
        final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
      }
    } catch (e) {
      // Fallback simples se tudo falhar
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = consultation.patientName ?? 'Paciente Anônimo';
    final date = _formatDate(consultation.startedAt);
    final isFinished = consultation.endedAt != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinished ? AppColors.success.withOpacity(0.3) : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFinished 
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFinished ? Icons.check_circle : Icons.medical_services,
                    color: isFinished ? AppColors.success : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFinished)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Finalizada',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
