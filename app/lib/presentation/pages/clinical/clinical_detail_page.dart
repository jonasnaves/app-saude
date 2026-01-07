import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/clinical_datasource.dart';
import '../../../data/models/consultation_model.dart';
import '../../../services/api_service.dart';
import '../../../utils/text_formatter.dart';
import '../../../utils/clipboard_service.dart';
import '../../../utils/anamnesis_parser.dart';
import '../../widgets/app_layout.dart';

class ClinicalDetailPage extends StatefulWidget {
  final String consultationId;

  const ClinicalDetailPage({super.key, required this.consultationId});

  @override
  State<ClinicalDetailPage> createState() => _ClinicalDetailPageState();
}

class _ClinicalDetailPageState extends State<ClinicalDetailPage> {
  final ClinicalDataSource _clinicalDataSource = ClinicalDataSource(ApiService());
  
  ConsultationModel? _consultation;
  bool _isLoading = true;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final consultation = await _clinicalDataSource.getConsultation(widget.consultationId);
      
      if (mounted) {
        setState(() {
          _consultation = consultation;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar consulta: $e')),
        );
      }
    }
  }

  Future<void> _resumeConsultation() async {
    try {
      setState(() {
        _isResuming = true;
      });
      
      await _clinicalDataSource.resumeConsultation(widget.consultationId);
      
      if (mounted) {
        // Navegar para página de gravação com consultationId
        context.go('/clinical/recording/${widget.consultationId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResuming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao retomar consulta: $e')),
        );
      }
    }
  }

  Widget _buildMinimalCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget content,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onCopy,
                    tooltip: 'Copiar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/clinical',
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/clinical');
                      }
                    },
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes da Consulta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_consultation?.patientName != null)
                          Text(
                            _consultation!.patientName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Botão Retornar à Consulta
                  if (_consultation != null)
                    ElevatedButton.icon(
                      onPressed: _isResuming ? null : _resumeConsultation,
                      icon: _isResuming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow, size: 18),
                      label: Text(_isResuming ? 'Retomando...' : 'Retornar à Consulta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
            // Conteúdo
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _consultation == null
                      ? Center(
                          child: Text(
                            'Consulta não encontrada',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Transcrição
                              if (_consultation!.transcript != null && _consultation!.transcript!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Transcrição',
                                  icon: Icons.description,
                                  accentColor: AppColors.textPrimary,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.transcript!,
                                    context,
                                  ),
                                  content: Text(
                                    _consultation!.transcript!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              
                              // Resumo Clínico
                              if (_consultation!.summary != null && _consultation!.summary!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Resumo Clínico',
                                  icon: Icons.summarize,
                                  accentColor: AppColors.primary,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.summary!,
                                    context,
                                  ),
                                  content: Text(
                                    TextFormatter.formatClinicalText(_consultation!.summary!),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              
                              // Anamnese Estruturada
                              if (_consultation!.anamnesis != null && _consultation!.anamnesis!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Anamnese',
                                  icon: Icons.medical_information,
                                  accentColor: AppColors.accent,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.anamnesis!,
                                    context,
                                  ),
                                  content: _buildAnamnesisSections(_consultation!.anamnesis!),
                                ),
                              
                              // Prescrição
                              if (_consultation!.prescription != null && _consultation!.prescription!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Prescrição',
                                  icon: Icons.medication,
                                  accentColor: AppColors.success,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.prescription!,
                                    context,
                                  ),
                                  content: Text(
                                    TextFormatter.formatPrescription(_consultation!.prescription),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              
                              // Medicamentos Sugeridos
                              if (_consultation!.suggestedMedications != null && _consultation!.suggestedMedications!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Medicamentos Sugeridos',
                                  icon: Icons.auto_awesome,
                                  accentColor: AppColors.warning,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.suggestedMedications!,
                                    context,
                                  ),
                                  content: Text(
                                    TextFormatter.formatSuggestedMedications(_consultation!.suggestedMedications),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              
                              // Perguntas Sugeridas
                              if (_consultation!.suggestedQuestions != null && _consultation!.suggestedQuestions!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Perguntas Sugeridas',
                                  icon: Icons.help_outline,
                                  accentColor: AppColors.info,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.suggestedQuestions!.join('\n• '),
                                    context,
                                  ),
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _consultation!.suggestedQuestions!.map((q) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '• ',
                                            style: TextStyle(
                                              color: AppColors.info,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              q,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              
                              // Notas do Médico
                              if (_consultation!.doctorNotes != null && _consultation!.doctorNotes!.isNotEmpty)
                                _buildMinimalCard(
                                  title: 'Notas do Médico',
                                  icon: Icons.note,
                                  accentColor: AppColors.warning,
                                  onCopy: () => ClipboardService.copyToClipboard(
                                    _consultation!.doctorNotes!,
                                    context,
                                  ),
                                  content: Text(
                                    _consultation!.doctorNotes!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              
                              // Informações adicionais se disponíveis
                              if (_consultation!.startedAt != null)
                                _buildMinimalCard(
                                  title: 'Informações',
                                  icon: Icons.info_outline,
                                  accentColor: AppColors.info,
                                  onCopy: null,
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        'Iniciada em',
                                        _formatDateTime(_consultation!.startedAt),
                                      ),
                                      if (_consultation!.endedAt != null)
                                        _buildInfoRow(
                                          'Finalizada em',
                                          _formatDateTime(_consultation!.endedAt!),
                                        ),
                                    ],
                                  ),
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

  Widget _buildAnamnesisSections(String anamnesisText) {
    final anamnesisSections = AnamnesisParser.parseAnamnesisSections(anamnesisText);
    final sectionLabels = AnamnesisParser.getSectionLabels();
    final sectionIcons = AnamnesisParser.getSectionIcons();
    final sectionColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: anamnesisSections.entries
          .where((e) => e.value.isNotEmpty)
          .map((entry) {
        final key = entry.key;
        final content = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    sectionIcons[key] ?? Icons.info,
                    size: 16,
                    color: sectionColors[
                        anamnesisSections.keys.toList().indexOf(key) %
                            sectionColors.length],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sectionLabels[key] ?? key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
