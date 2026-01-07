import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class RecordingFAB extends StatelessWidget {
  final bool isRecording;

  const RecordingFAB({super.key, this.isRecording = false});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (isRecording) {
          // Stop recording
        } else {
          context.go('/clinical/recording');
        }
      },
      backgroundColor: isRecording ? AppColors.error : AppColors.primary,
      child: isRecording
          ? const Icon(Icons.stop, color: Colors.white)
          : const Icon(Icons.mic, color: Colors.white),
    );
  }
}

