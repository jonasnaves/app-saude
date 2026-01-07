import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/datasources/patient_datasource.dart';
import '../../../data/models/patient_model.dart';
import '../../../services/api_service.dart';

class PatientDetailPage extends StatefulWidget {
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final PatientDataSource _patientDataSource = PatientDataSource(ApiService());
  PatientModel? _patient;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final patient = await _patientDataSource.getPatient(widget.patientId);
      setState(() {
        _patient = patient;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar paciente: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _patient == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error ?? 'Paciente não encontrado'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
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
          _patient!.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => context.push('/patients/${_patient!.id}/edit'),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.push('/clinical/recording?patientId=${_patient!.id}'),
            tooltip: 'Nova consulta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto
            _buildHeader(),
            const SizedBox(height: 24),
            // Dados pessoais
            _buildSection('Dados Pessoais', _buildPersonalInfo()),
            // Endereço
            if (_patient!.address != null)
              _buildSection('Endereço', _buildAddressInfo()),
            // Informações de saúde
            _buildSection('Informações de Saúde', _buildHealthInfo()),
            // Fotos
            if (_patient!.photos.isNotEmpty)
              _buildSection('Fotos', _buildPhotosGallery()),
            // Documentos
            if (_patient!.documents.isNotEmpty)
              _buildSection('Documentos', _buildDocumentsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: _patient!.mainPhoto != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          '${ApiConstants.baseUrl.replaceAll('/api', '')}${_patient!.mainPhoto}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        color: AppColors.textTertiary,
                        size: 48,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_patient!.age != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_patient!.age} anos',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_patient!.cpf != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'CPF: ${_patient!.cpf}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        _buildInfoRow('Telefone', _patient!.phone),
        _buildInfoRow('E-mail', _patient!.email),
        _buildInfoRow('RG', _patient!.rg),
        _buildInfoRow(
          'Data de nascimento',
          _patient!.birthDate != null
              ? DateFormat('dd/MM/yyyy').format(_patient!.birthDate!)
              : null,
        ),
        _buildInfoRow('Sexo', _getGenderLabel(_patient!.gender)),
      ],
    );
  }

  Widget _buildAddressInfo() {
    final addr = _patient!.address!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${addr.street}, ${addr.number}'),
        if (addr.complement != null) Text(addr.complement!),
        Text('${addr.neighborhood}, ${addr.city} - ${addr.state}'),
        Text('CEP: ${addr.zipCode}'),
      ],
    );
  }

  Widget _buildHealthInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_patient!.medicalHistory != null) ...[
          const Text(
            'Histórico Médico',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _patient!.medicalHistory!,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
        if (_patient!.allergies != null && _patient!.allergies!.isNotEmpty) ...[
          const Text(
            'Alergias',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _patient!.allergies!.map((a) => Chip(label: Text(a))).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (_patient!.currentMedications != null &&
            _patient!.currentMedications!.isNotEmpty) ...[
          const Text(
            'Medicamentos em uso',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _patient!.currentMedications!.map((m) => Chip(label: Text(m))).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotosGallery() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _patient!.photos.length,
      itemBuilder: (context, index) {
        final photoUrl = _patient!.photos[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: Colors.black,
                  body: PhotoView(
                    imageProvider: CachedNetworkImageProvider(
                      '${ApiConstants.baseUrl.replaceAll('/api', '')}$photoUrl',
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: '${ApiConstants.baseUrl.replaceAll('/api', '')}$photoUrl',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surfaceElevated,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceElevated,
                child: Icon(Icons.broken_image, color: AppColors.textTertiary),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    return Column(
      children: _patient!.documents.map((doc) {
        return ListTile(
          leading: Icon(Icons.description, color: AppColors.primary),
          title: Text(doc.name, style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(
            '${doc.type} • ${doc.size != null ? '${(doc.size! / 1024).toStringAsFixed(1)} KB' : 'N/A'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: () {
              // TODO: Implementar download
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getGenderLabel(String? gender) {
    switch (gender) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Feminino';
      case 'O':
        return 'Outro';
      case 'N':
        return 'Não informado';
      default:
        return null;
    }
  }
}


