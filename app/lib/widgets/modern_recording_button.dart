import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/colors.dart';

enum RecordingState { idle, recording, paused }

class ModernRecordingButton extends StatefulWidget {
  final RecordingState state;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onResume;

  const ModernRecordingButton({
    super.key,
    required this.state,
    this.onStart,
    this.onStop,
    this.onResume,
  });

  @override
  State<ModernRecordingButton> createState() => _ModernRecordingButtonState();
}

class _ModernRecordingButtonState extends State<ModernRecordingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _gradientController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animação de ondas
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOut),
    );

    // Animação de gradiente
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(ModernRecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == RecordingState.recording) {
        _pulseController.repeat();
        _waveController.repeat();
      } else {
        _pulseController.stop();
        _waveController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _handleTap() {
    switch (widget.state) {
      case RecordingState.idle:
        widget.onStart?.call();
        break;
      case RecordingState.recording:
        widget.onStop?.call();
        break;
      case RecordingState.paused:
        widget.onResume?.call();
        break;
    }
  }

  Color _getButtonColor() {
    switch (widget.state) {
      case RecordingState.idle:
        return AppColors.primary;
      case RecordingState.recording:
        return AppColors.error;
      case RecordingState.paused:
        return AppColors.warning;
    }
  }

  IconData _getIcon() {
    switch (widget.state) {
      case RecordingState.idle:
        return Icons.mic;
      case RecordingState.recording:
        return Icons.stop;
      case RecordingState.paused:
        return Icons.play_arrow;
    }
  }

  String _getLabel() {
    switch (widget.state) {
      case RecordingState.idle:
        return 'Iniciar Gravação';
      case RecordingState.recording:
        return 'Parar Gravação';
      case RecordingState.paused:
        return 'Retomar Gravação';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state == RecordingState.recording;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getButtonColor().withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: isRecording ? 10 : 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ondas sonoras (quando gravando)
            if (isRecording)
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    final delay = index * 0.3;
                    final animationValue = ((_waveAnimation.value + delay) % 1.0);
                    final scale = 1.0 + (animationValue * 0.8);
                    final opacity = 1.0 - animationValue;

                    return Container(
                      width: 80 * scale,
                      height: 80 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getButtonColor().withOpacity(opacity * 0.3),
                          width: 2,
                        ),
                      ),
                    );
                  },
                );
              }),

            // Botão principal com animação de pulso
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getButtonColor(),
                          _getButtonColor().withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor().withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate(target: isRecording ? 1 : 0)
        .scale(duration: 300.ms, curve: Curves.easeOut);
  }
}

