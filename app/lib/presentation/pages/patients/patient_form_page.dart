import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/patient_datasource.dart';
import '../../../data/models/patient_model.dart';
import '../../../services/api_service.dart';
import '../../widgets/photo_upload_widget.dart';
import '../../widgets/document_upload_widget.dart';
import 'dart:typed_data';

class PatientFormPage extends StatefulWidget {
  final String? patientId;

  const PatientFormPage({super.key, this.patientId});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PatientDataSource _patientDataSource = PatientDataSource(ApiService());

  // Controllers
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _rgController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  List<String> _allergies = [];
  List<String> _currentMedications = [];
  List<String> _chronicConditions = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<String> _photos = [];
  List<PatientDocument> _documents = [];

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) {
      _loadPatient();
    }
  }

  Future<void> _loadPatient() async {
    setState(() => _isLoading = true);
    try {
      final patient = await _patientDataSource.getPatient(widget.patientId!);
      _populateForm(patient);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar paciente: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(PatientModel patient) {
    _nameController.text = patient.name;
    _cpfController.text = patient.cpf ?? '';
    _rgController.text = patient.rg ?? '';
    _phoneController.text = patient.phone ?? '';
    _emailController.text = patient.email ?? '';
    _birthDate = patient.birthDate;
    _gender = patient.gender;
    _allergies = patient.allergies ?? [];
    _currentMedications = patient.currentMedications ?? [];
    _chronicConditions = patient.chronicConditions ?? [];
    _emergencyContacts = patient.emergencyContacts ?? [];
    _photos = patient.photos;
    _documents = patient.documents;
    _medicalHistoryController.text = patient.medicalHistory ?? '';

    if (patient.address != null) {
      _streetController.text = patient.address!.street;
      _numberController.text = patient.address!.number;
      _complementController.text = patient.address!.complement ?? '';
      _neighborhoodController.text = patient.address!.neighborhood;
      _cityController.text = patient.address!.city;
      _stateController.text = patient.address!.state;
      _zipCodeController.text = patient.address!.zipCode;
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final patient = PatientModel(
        id: widget.patientId ?? '',
        name: _nameController.text.trim(),
        cpf: _cpfController.text.trim().isEmpty ? null : _cpfController.text.trim(),
        rg: _rgController.text.trim().isEmpty ? null : _rgController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _streetController.text.trim().isNotEmpty
            ? PatientAddress(
                street: _streetController.text.trim(),
                number: _numberController.text.trim(),
                complement: _complementController.text.trim().isEmpty
                    ? null
                    : _complementController.text.trim(),
                neighborhood: _neighborhoodController.text.trim(),
                city: _cityController.text.trim(),
                state: _stateController.text.trim(),
                zipCode: _zipCodeController.text.trim(),
              )
            : null,
        allergies: _allergies.isEmpty ? null : _allergies,
        medicalHistory: _medicalHistoryController.text.trim().isEmpty
            ? null
            : _medicalHistoryController.text.trim(),
        currentMedications: _currentMedications.isEmpty ? null : _currentMedications,
        chronicConditions: _chronicConditions.isEmpty ? null : _chronicConditions,
        emergencyContacts: _emergencyContacts.isEmpty ? null : _emergencyContacts,
        photos: _photos,
        documents: _documents,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.patientId != null) {
        await _patientDataSource.updatePatient(widget.patientId!, patient);
      } else {
        await _patientDataSource.createPatient(patient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente salvo com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar paciente: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePhotoUpload(Uint8List bytes, String fileName) async {
    if (widget.patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salve o paciente primeiro para adicionar fotos')),
      );
      return;
    }

    try {
      final result = await _patientDataSource.uploadPhoto(widget.patientId!, bytes, fileName);
      setState(() {
        _photos = result['patient'].photos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload: $e')),
        );
      }
    }
  }

  Future<void> _handleDocumentUpload(Uint8List bytes, String fileName) async {
    if (widget.patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salve o paciente primeiro para adicionar documentos')),
      );
      return;
    }

    try {
      final result = await _patientDataSource.uploadDocument(widget.patientId!, bytes, fileName);
      setState(() {
        _documents = result['patient'].documents;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.patientId == null ? 'Novo Paciente' : 'Editar Paciente',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePatient,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Dados Pessoais', [
                _buildTextField(_nameController, 'Nome completo *', Icons.person),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_cpfController, 'CPF', Icons.badge)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_rgController, 'RG', Icons.badge_outlined)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField('Data de nascimento', _birthDate, (date) {
                        setState(() => _birthDate = date);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        'Sexo',
                        _gender,
                        ['M', 'F', 'O', 'N'],
                        {'M': 'Masculino', 'F': 'Feminino', 'O': 'Outro', 'N': 'Não informado'},
                        (value) => setState(() => _gender = value),
                      ),
                    ),
                  ],
                ),
                _buildTextField(_phoneController, 'Telefone', Icons.phone),
                _buildTextField(_emailController, 'E-mail', Icons.email),
              ]),
              _buildSection('Endereço', [
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTextField(_streetController, 'Rua', Icons.home)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_numberController, 'Nº', Icons.numbers)),
                  ],
                ),
                _buildTextField(_complementController, 'Complemento', Icons.home_work),
                _buildTextField(_neighborhoodController, 'Bairro', Icons.location_city),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildTextField(_cityController, 'Cidade', Icons.location_city)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_stateController, 'Estado', Icons.map)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_zipCodeController, 'CEP', Icons.pin)),
                  ],
                ),
              ]),
              _buildSection('Informações de Saúde', [
                _buildTextArea(_medicalHistoryController, 'Histórico médico'),
                _buildChipList('Alergias', _allergies, (items) => setState(() => _allergies = items)),
                _buildChipList('Medicamentos em uso', _currentMedications,
                    (items) => setState(() => _currentMedications = items)),
                _buildChipList('Condições crônicas', _chronicConditions,
                    (items) => setState(() => _chronicConditions = items)),
              ]),
              if (widget.patientId != null) ...[
                _buildSection('Fotos', [
                  PhotoUploadWidget(
                    photos: _photos,
                    onPhotoAdded: (url) {},
                    onPhotoRemoved: (url) async {
                      try {
                        final fileName = url.split('/').last;
                        await _patientDataSource.deletePhoto(widget.patientId!, fileName);
                        setState(() => _photos.remove(url));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir foto: $e')),
                          );
                        }
                      }
                    },
                    onPhotoUpload: _handlePhotoUpload,
                  ),
                ]),
                _buildSection('Documentos', [
                  DocumentUploadWidget(
                    documents: _documents,
                    onDocumentAdded: (doc) {},
                    onDocumentRemoved: (docId) async {
                      try {
                        await _patientDataSource.deleteDocument(widget.patientId!, docId);
                        setState(() => _documents.removeWhere((d) => d.id == docId));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir documento: $e')),
                          );
                        }
                      }
                    },
                    onDocumentUpload: _handleDocumentUpload,
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: label.contains('*') && controller.text.trim().isEmpty
            ? (value) => 'Campo obrigatório'
            : null,
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null) onChanged(date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Text(
            value != null ? DateFormat('dd/MM/yyyy').format(value) : '',
            style: TextStyle(
              color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    Map<T, String>? labels,
    Function(T?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(labels?[item] ?? item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildChipList(String label, List<String> items, Function(List<String>) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...items.map((item) => Chip(
                    label: Text(item),
                    onDeleted: () => onChanged(items.where((i) => i != item).toList()),
                  )),
              ActionChip(
                label: const Text('+ Adicionar'),
                onPressed: () async {
                  final text = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Adicionar $label'),
                      content: TextField(
                        autofocus: true,
                        onSubmitted: (value) => Navigator.pop(context, value),
                      ),
                    ),
                  );
                  if (text != null && text.isNotEmpty) {
                    onChanged([...items, text]);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

