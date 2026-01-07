import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/datasources/patient_datasource.dart';
import '../../data/models/patient_model.dart';
import '../../services/api_service.dart';

class PatientSelectorWidget extends StatefulWidget {
  final Function(String? patientId, String? anonymousName) onPatientSelected;

  const PatientSelectorWidget({super.key, required this.onPatientSelected});

  @override
  State<PatientSelectorWidget> createState() => _PatientSelectorWidgetState();
}

class _PatientSelectorWidgetState extends State<PatientSelectorWidget> {
  final PatientDataSource _patientDataSource = PatientDataSource(ApiService());
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _anonymousNameController = TextEditingController();

  List<PatientModel> _patients = [];
  bool _isLoading = false;
  String? _selectedPatientId;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadPatients();
    });
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final result = await _patientDataSource.getPatients(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        limit: 20,
      );
      setState(() {
        _patients = result['patients'] as List<PatientModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _anonymousNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Paciente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Opções
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Paciente existente'),
                    selected: !_isAnonymous,
                    onSelected: (selected) {
                      setState(() {
                        _isAnonymous = false;
                        _selectedPatientId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Consulta anônima'),
                    selected: _isAnonymous,
                    onSelected: (selected) {
                      setState(() {
                        _isAnonymous = true;
                        _selectedPatientId = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isAnonymous) ...[
              // Busca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar pacientes...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              // Lista de pacientes
              Flexible(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _patients.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum paciente encontrado',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _patients.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return ListTile(
                                  leading: const Icon(Icons.add_circle_outline,
                                      color: AppColors.primary),
                                  title: const Text(
                                    'Criar novo paciente',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  onTap: () {
                                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                                      Navigator.of(context, rootNavigator: true).pop();
                                    }
                                    // Navegar para criar paciente
                                    context.push('/patients/new');
                                  },
                                );
                              }

                              final patient = _patients[index - 1];
                              final isSelected = _selectedPatientId == patient.id;

                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceElevated,
                                  ),
                                  child: patient.mainPhoto != null
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                '${ApiConstants.baseUrl.replaceAll('/api', '')}${patient.mainPhoto}',
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person,
                                              color: AppColors.textTertiary,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: AppColors.textTertiary,
                                          size: 20,
                                        ),
                                ),
                                title: Text(
                                  patient.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                subtitle: patient.age != null
                                    ? Text(
                                        '${patient.age} anos',
                                        style: const TextStyle(color: AppColors.textSecondary),
                                      )
                                    : null,
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedPatientId = patient.id);
                                },
                              );
                            },
                          ),
              ),
            ] else ...[
              TextField(
                controller: _anonymousNameController,
                decoration: InputDecoration(
                  labelText: 'Nome do paciente (opcional)',
                  hintText: 'Ex: Paciente Anônimo',
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
            const SizedBox(height: 24),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (!_isAnonymous && _selectedPatientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um paciente ou escolha consulta anônima'),
                        ),
                      );
                      return;
                    }

                    widget.onPatientSelected(
                      _isAnonymous ? null : _selectedPatientId,
                      _isAnonymous && _anonymousNameController.text.isNotEmpty
                          ? _anonymousNameController.text
                          : null,
                    );
                    // Fechar dialog de forma segura
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

