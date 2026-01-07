import 'dart:convert';

class TextFormatter {
  /// Formata texto que pode estar em formato JSON ou texto simples
  /// Retorna texto formatado de forma legível
  static String formatClinicalText(String text) {
    if (text.isEmpty) return text;

    // Limpar texto primeiro
    String cleanedText = text.trim();

    // Tentar parsear como JSON
    try {
      final jsonData = jsonDecode(cleanedText);
      return _formatJsonToReadable(jsonData);
    } catch (e) {
      // Se não for JSON válido, tentar extrair JSON de dentro do texto
      final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(cleanedText);
      if (jsonMatch != null) {
        try {
          final jsonData = jsonDecode(jsonMatch.group(0)!);
          return _formatJsonToReadable(jsonData);
        } catch (e2) {
          // Se ainda falhar, formatar como texto simples
          return _formatPlainText(cleanedText);
        }
      }
      // Se não for JSON, formatar como texto simples
      return _formatPlainText(cleanedText);
    }
  }

  /// Formata objeto JSON em texto legível
  static String _formatJsonToReadable(dynamic jsonData) {
    if (jsonData is Map) {
      return _formatMap(jsonData, 0);
    } else if (jsonData is List) {
      return _formatList(jsonData, 0);
    } else {
      return jsonData.toString();
    }
  }

  /// Formata um Map em texto legível
  static String _formatMap(Map<dynamic, dynamic> map, int indent) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    map.forEach((key, value) {
      final keyStr = _formatKey(key.toString());
      
      if (value is Map && value.isNotEmpty) {
        buffer.writeln('$indentStr$keyStr:');
        buffer.write(_formatMap(value, indent + 1));
      } else if (value is List && value.isNotEmpty) {
        buffer.writeln('$indentStr$keyStr:');
        buffer.write(_formatList(value, indent + 1));
      } else {
        final valueStr = _formatValue(value);
        // Se o valor for muito longo, quebrar em múltiplas linhas
        if (valueStr.length > 80 && !valueStr.contains('\n')) {
          buffer.writeln('$indentStr$keyStr:');
          buffer.writeln('${indentStr}  $valueStr');
        } else {
          buffer.writeln('$indentStr$keyStr: $valueStr');
        }
      }
    });
    
    return buffer.toString();
  }

  /// Formata uma List em texto legível
  static String _formatList(List<dynamic> list, int indent) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    for (var item in list) {
      if (item is Map) {
        buffer.writeln('$indentStr•');
        buffer.write(_formatMap(item, indent + 1));
      } else if (item is List) {
        buffer.writeln('$indentStr•');
        buffer.write(_formatList(item, indent + 1));
      } else {
        buffer.writeln('$indentStr• ${_formatValue(item)}');
      }
    }
    
    return buffer.toString();
  }

  /// Formata chave de forma legível
  static String _formatKey(String key) {
    // Converter snake_case ou camelCase para formato legível
    String formatted = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    
    // Capitalizar primeira letra
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }
    
    return formatted;
  }

  /// Formata valor de forma legível
  static String _formatValue(dynamic value) {
    if (value == null) return 'Não informado';
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 'Não informado';
      
      // Se for uma string que parece JSON, tentar formatar
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final parsed = jsonDecode(trimmed);
          return '\n${_formatJsonToReadable(parsed)}';
        } catch (e) {
          // Se falhar, retornar a string original
          return value;
        }
      }
      
      // Se for uma lista em formato de string (ex: "[item1, item2]")
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is List) {
            return parsed.map((e) => e.toString()).join(', ');
          }
        } catch (e) {
          // Se falhar, retornar a string original
        }
      }
      
      return value;
    }
    if (value is bool) {
      return value ? 'Sim' : 'Não';
    }
    return value.toString();
  }

  /// Formata texto simples removendo caracteres JSON desnecessários
  static String _formatPlainText(String text) {
    // Se o texto já estiver bem formatado (com quebras de linha e estrutura), retornar como está
    if (text.contains('\n') && text.split('\n').length > 3) {
      return text.trim();
    }

    // Remover chaves e colchetes se parecer JSON mal formatado
    String formatted = text
        .replaceAll(RegExp(r'\{|\}'), '')
        .replaceAll(RegExp(r'\[|\]'), '')
        .replaceAll(RegExp(r'",\s*"'), '\n')
        .replaceAll(RegExp(r'":\s*"'), ': ')
        .replaceAll(RegExp(r'":\s*'), ': ')
        .replaceAll('"', '')
        .trim();

    // Adicionar quebras de linha após dois pontos seguidos de texto
    formatted = formatted.replaceAllMapped(
      RegExp(r':\s*([^:\n]{20,})'),
      (match) => ':\n  ${match.group(1)}',
    );

    // Adicionar quebras de linha antes de palavras-chave comuns em textos médicos
    final keywords = [
      'Queixa Principal',
      'História da Doença',
      'Exame Físico',
      'Hipótese Diagnóstica',
      'Conduta',
      'Prescrição',
      'Orientações',
      'Retorno',
    ];
    
    for (var keyword in keywords) {
      formatted = formatted.replaceAll(
        RegExp('$keyword:', caseSensitive: false),
        '\n\n$keyword:',
      );
    }

    // Limpar múltiplas quebras de linha
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return formatted.trim();
  }

  /// Formata texto de prescrição de forma especial
  static String formatPrescription(String? prescription) {
    if (prescription == null || prescription.isEmpty) {
      return 'Nenhuma prescrição identificada.';
    }

    // Tentar parsear como JSON primeiro
    try {
      final jsonData = jsonDecode(prescription);
      return _formatJsonToReadable(jsonData);
    } catch (e) {
      // Se não for JSON, formatar como lista de itens
      final lines = prescription.split('\n');
      final buffer = StringBuffer();
      
      for (var line in lines) {
        line = line.trim();
        if (line.isNotEmpty) {
          // Se a linha começa com número ou bullet, manter
          if (RegExp(r'^[\d•\-]').hasMatch(line)) {
            buffer.writeln(line);
          } else {
            buffer.writeln('• $line');
          }
        }
      }
      
      return buffer.toString().trim();
    }
  }

  /// Formata texto de medicamentos sugeridos pela IA
  static String formatSuggestedMedications(String? suggestedMedications) {
    if (suggestedMedications == null || suggestedMedications.isEmpty) {
      return 'Nenhum medicamento sugerido pela IA.';
    }

    // Tentar parsear como JSON primeiro
    try {
      final jsonData = jsonDecode(suggestedMedications);
      return _formatJsonToReadable(jsonData);
    } catch (e) {
      // Se não for JSON, formatar como lista de itens
      final lines = suggestedMedications.split('\n');
      final buffer = StringBuffer();
      
      for (var line in lines) {
        line = line.trim();
        if (line.isNotEmpty) {
          // Se a linha começa com número ou bullet, manter
          if (RegExp(r'^[\d•\-]').hasMatch(line)) {
            buffer.writeln(line);
          } else {
            buffer.writeln('• $line');
          }
        }
      }
      
      return buffer.toString().trim();
    }
  }
}

