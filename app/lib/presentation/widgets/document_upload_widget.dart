import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/patient_model.dart';

class DocumentUploadWidget extends StatefulWidget {
  final List<PatientDocument> documents;
  final Function(PatientDocument doc) onDocumentAdded;
  final Function(String docId) onDocumentRemoved;
  final Function(Uint8List bytes, String fileName) onDocumentUpload;

  const DocumentUploadWidget({
    super.key,
    required this.documents,
    required this.onDocumentAdded,
    required this.onDocumentRemoved,
    required this.onDocumentUpload,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _isUploading = false;

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isUploading = true);

        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        await widget.onDocumentUpload(bytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar documento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Documentos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.primary),
                onPressed: _pickAndUploadDocument,
                tooltip: 'Adicionar documento',
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum documento adicionado',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.documents.length,
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getDocumentIcon(doc.type),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (doc.size != null)
                            Text(
                              '${(doc.size! / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => widget.onDocumentRemoved(doc.id),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}


