import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../utils/text_formatter.dart';
import '../utils/clipboard_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnamnesisSectionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final int index; // Para animação escalonada

  const AnamnesisSectionCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withOpacity(0.8),
            AppColors.surface.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com título e botão de copiar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: color, size: 18),
                  onPressed: () {
                    ClipboardService.copyToClipboard(content, context);
                  },
                  tooltip: 'Copiar $title',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              TextFormatter.formatClinicalText(content),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (index * 100).ms, curve: Curves.easeOut);
  }
}

