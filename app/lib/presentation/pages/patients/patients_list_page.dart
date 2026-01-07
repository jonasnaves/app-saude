import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/datasources/patient_datasource.dart';
import '../../../data/models/patient_model.dart';
import '../../../services/api_service.dart';
import '../../widgets/app_layout.dart';
import 'patient_form_page.dart';
import 'patient_detail_page.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  final PatientDataSource _patientDataSource =
      PatientDataSource(ApiService());
  final TextEditingController _searchController = TextEditingController();

  List<PatientModel> _patients = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchController.text) {
        _loadPatients(reset: true);
      }
    });
  }

  Future<void> _loadPatients({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _patientDataSource.getPatients(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        if (reset) {
          _patients = result['patients'] as List<PatientModel>;
        } else {
          _patients.addAll(result['patients'] as List<PatientModel>);
        }
        _total = result['total'] as int;
        _currentPage++;
        _hasMore = _patients.length < _total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar pacientes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient(PatientModel patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Excluir Paciente',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tem certeza que deseja excluir ${patient.name}? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _patientDataSource.deletePatient(patient.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente excluído com sucesso'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadPatients(reset: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir paciente: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: '/patients',
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
                    onPressed: () => context.pop(),
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pacientes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    color: AppColors.primary,
                    onPressed: () => context.push('/patients/new'),
                    tooltip: 'Novo paciente',
                  ),
                ],
              ),
            ),
            // Busca
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _loadPatients(reset: true);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            // Conteúdo
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadPatients(reset: true),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _patients.isEmpty && !_isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhum paciente encontrado',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context.push('/patients/new'),
                                child: const Text('Adicionar primeiro paciente'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400, // Largura máxima de cada card
                            childAspectRatio: 1.1, // Proporção ajustada
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _patients.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _patients.length) {
                              // Load more trigger
                              if (_hasMore && !_isLoading) {
                                _loadPatients();
                              }
                              return _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : const SizedBox.shrink();
                            }

                            final patient = _patients[index];
                            return _PatientCard(
                              patient: patient,
                              onTap: () => context.push('/patients/${patient.id}'),
                              onEdit: () => context.push('/patients/${patient.id}/edit'),
                              onDelete: () => _deletePatient(patient),
                            ).animate().fadeIn(duration: 300.ms).slideY(
                                  begin: 0.1,
                                  end: 0,
                                  duration: 300.ms,
                                  delay: (index * 50).ms,
                                );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com foto e ações
                Row(
                  children: [
                    // Foto do paciente
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: patient.mainPhoto != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: '${ApiConstants.baseUrl.replaceAll('/api', '')}${patient.mainPhoto}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  color: AppColors.textTertiary,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: AppColors.textTertiary,
                              size: 32,
                            ),
                    ),
                    const Spacer(),
                    // Menu de ações
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                      color: AppColors.surface,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 8),
                              const Text('Editar', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              const Text('Excluir', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nome
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Informações
                if (patient.age != null)
                  _InfoRow(
                    icon: Icons.cake,
                    text: '${patient.age} anos',
                  ),
                if (patient.cpf != null)
                  _InfoRow(
                    icon: Icons.badge,
                    text: patient.cpf!,
                  ),
                if (patient.phone != null)
                  _InfoRow(
                    icon: Icons.phone,
                    text: patient.phone!,
                  ),
                const Spacer(),
                // Footer com data
                Text(
                  'Criado em ${_formatDate(patient.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

