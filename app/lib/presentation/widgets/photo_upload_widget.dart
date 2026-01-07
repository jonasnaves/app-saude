import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';

class PhotoUploadWidget extends StatefulWidget {
  final List<String> photos;
  final Function(String url) onPhotoAdded;
  final Function(String url) onPhotoRemoved;
  final Function(Uint8List bytes, String fileName) onPhotoUpload;

  const PhotoUploadWidget({
    super.key,
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    required this.onPhotoUpload,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isUploading = true);

        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        await widget.onPhotoUpload(bytes, fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar foto: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Fotos',
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
                icon: const Icon(Icons.add_photo_alternate, color: AppColors.primary),
                onPressed: _pickAndUploadPhoto,
                tooltip: 'Adicionar foto',
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.photos.isEmpty)
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
                  Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma foto adicionada',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photoUrl = widget.photos[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: '${ApiConstants.baseUrl.replaceAll('/api', '')}$photoUrl',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => widget.onPhotoRemoved(photoUrl),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}


