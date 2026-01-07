import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ClipboardService {
  /// Copia texto para a área de transferência
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    if (text.isEmpty) return;
    
    try {
      await Clipboard.setData(ClipboardData(text: text));
      
      // Mostrar feedback visual
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Texto copiado para a área de transferência'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao copiar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Copia múltiplos textos concatenados
  static Future<void> copyMultipleToClipboard(
    List<String> texts,
    BuildContext context,
  ) async {
    final combinedText = texts.where((t) => t.isNotEmpty).join('\n\n');
    await copyToClipboard(combinedText, context);
  }
}


