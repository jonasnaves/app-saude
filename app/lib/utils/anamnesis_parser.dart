import 'package:flutter/material.dart';

class AnamnesisParser {
  /// Extrai seções da anamnese em formato estruturado
  static Map<String, String> parseAnamnesisSections(String anamnesisText) {
    if (anamnesisText.isEmpty) {
      return {
        'queixaPrincipal': '',
        'historiaDoenca': '',
        'exameFisico': '',
        'hipoteseDiagnostica': '',
        'conduta': '',
      };
    }

    // Tentar parsear formato estruturado (JSON-like ou formato com chaves)
    try {
      String text = anamnesisText.trim();
      
      // Se começa com {, tentar parsear formato estruturado
      if (text.startsWith('{')) {
        final result = <String, String>{
          'queixaPrincipal': '',
          'historiaDoenca': '',
          'exameFisico': '',
          'hipoteseDiagnostica': '',
          'conduta': '',
        };
        
        // Extrair Queixa Principal
        final qpMatch = RegExp(r'Queixa\s+Principal[:\s]*\[([^\]]+)\]', caseSensitive: false).firstMatch(text);
        if (qpMatch != null) {
          result['queixaPrincipal'] = qpMatch.group(1)?.trim() ?? '';
        } else {
          final qpMatch2 = RegExp(r'Queixa\s+Principal[:\s]*([^,}]+)', caseSensitive: false).firstMatch(text);
          if (qpMatch2 != null) {
            result['queixaPrincipal'] = qpMatch2.group(1)?.trim() ?? '';
          }
        }
        
        // Extrair História da Doença
        final hdMatch = RegExp(r'Hist[oó]ria\s+da\s+Doen[çc]a[:\s]*\{([^}]+)\}', caseSensitive: false, dotAll: true).firstMatch(text);
        if (hdMatch != null) {
          result['historiaDoenca'] = _formatStructuredText(hdMatch.group(1)?.trim() ?? '');
        } else {
          final hdMatch2 = RegExp(r'Hist[oó]ria\s+da\s+Doen[çc]a[:\s]*([^,}]+)', caseSensitive: false, dotAll: true).firstMatch(text);
          if (hdMatch2 != null) {
            result['historiaDoenca'] = hdMatch2.group(1)?.trim() ?? '';
          }
        }
        
        // Extrair Exame Físico
        final efMatch = RegExp(r'Exame\s+F[íi]sico[:\s]*([^,}]+)', caseSensitive: false, dotAll: true).firstMatch(text);
        if (efMatch != null) {
          result['exameFisico'] = efMatch.group(1)?.trim() ?? '';
        }
        
        // Extrair Hipótese Diagnóstica
        final hdMatch3 = RegExp(r'Hip[óo]tese\s+Diagn[óo]stica[:\s]*\[([^\]]+)\]', caseSensitive: false).firstMatch(text);
        if (hdMatch3 != null) {
          result['hipoteseDiagnostica'] = hdMatch3.group(1)?.trim() ?? '';
        } else {
          final hdMatch4 = RegExp(r'Hip[óo]tese\s+Diagn[óo]stica[:\s]*([^,}]+)', caseSensitive: false, dotAll: true).firstMatch(text);
          if (hdMatch4 != null) {
            result['hipoteseDiagnostica'] = hdMatch4.group(1)?.trim() ?? '';
          }
        }
        
        // Extrair Conduta
        final condMatch = RegExp(r'Conduta[:\s]*\[([^\]]+)\]', caseSensitive: false).firstMatch(text);
        if (condMatch != null) {
          result['conduta'] = condMatch.group(1)?.trim() ?? '';
        } else {
          final condMatch2 = RegExp(r'Conduta[:\s]*([^,}]+)', caseSensitive: false, dotAll: true).firstMatch(text);
          if (condMatch2 != null) {
            result['conduta'] = condMatch2.group(1)?.trim() ?? '';
          }
        }
        
        // Se conseguiu extrair pelo menos uma seção, retornar
        if (result.values.any((v) => v.isNotEmpty)) {
          print('[AnamnesisParser] Parseado formato estruturado: ${result.keys.where((k) => result[k]!.isNotEmpty).toList()}');
          return result;
        }
      }
    } catch (e) {
      // Se falhar, continuar com o parsing normal
      print('[AnamnesisParser] Erro ao parsear formato estruturado: $e');
    }

    // Normalizar texto: remover espaços extras e quebras de linha múltiplas
    String normalized = anamnesisText
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Padrões para identificar seções (case insensitive)
    final patterns = {
      'queixaPrincipal': [
        RegExp(r'queixa\s+principal[:\s]*(.+?)(?=\n\n|\n(?:história|historia|exame|hipótese|hipotese|conduta|$))', caseSensitive: false, dotAll: true),
        RegExp(r'queixa[:\s]*(.+?)(?=\n\n|\n(?:história|historia|exame|hipótese|hipotese|conduta|$))', caseSensitive: false, dotAll: true),
      ],
      'historiaDoenca': [
        RegExp(r'história\s+da\s+doença[:\s]*(.+?)(?=\n\n|\n(?:exame|hipótese|hipotese|conduta|queixa|$))', caseSensitive: false, dotAll: true),
        RegExp(r'historia\s+da\s+doenca[:\s]*(.+?)(?=\n\n|\n(?:exame|hipótese|hipotese|conduta|queixa|$))', caseSensitive: false, dotAll: true),
        RegExp(r'hda[:\s]*(.+?)(?=\n\n|\n(?:exame|hipótese|hipotese|conduta|queixa|$))', caseSensitive: false, dotAll: true),
      ],
      'exameFisico': [
        RegExp(r'exame\s+físico[:\s]*(.+?)(?=\n\n|\n(?:hipótese|hipotese|conduta|queixa|história|historia|$))', caseSensitive: false, dotAll: true),
        RegExp(r'exame\s+fisico[:\s]*(.+?)(?=\n\n|\n(?:hipótese|hipotese|conduta|queixa|história|historia|$))', caseSensitive: false, dotAll: true),
        RegExp(r'ef[:\s]*(.+?)(?=\n\n|\n(?:hipótese|hipotese|conduta|queixa|história|historia|$))', caseSensitive: false, dotAll: true),
      ],
      'hipoteseDiagnostica': [
        RegExp(r'hipótese\s+diagnóstica[:\s]*(.+?)(?=\n\n|\n(?:conduta|queixa|história|historia|exame|$))', caseSensitive: false, dotAll: true),
        RegExp(r'hipotese\s+diagnostica[:\s]*(.+?)(?=\n\n|\n(?:conduta|queixa|história|historia|exame|$))', caseSensitive: false, dotAll: true),
        RegExp(r'diagnóstico[:\s]*(.+?)(?=\n\n|\n(?:conduta|queixa|história|historia|exame|$))', caseSensitive: false, dotAll: true),
        RegExp(r'diagnostico[:\s]*(.+?)(?=\n\n|\n(?:conduta|queixa|história|historia|exame|$))', caseSensitive: false, dotAll: true),
      ],
      'conduta': [
        RegExp(r'conduta[:\s]*(.+?)(?=\n\n|\n(?:queixa|história|historia|exame|hipótese|hipotese|$))', caseSensitive: false, dotAll: true),
        RegExp(r'orientações[:\s]*(.+?)(?=\n\n|\n(?:queixa|história|historia|exame|hipótese|hipotese|$))', caseSensitive: false, dotAll: true),
        RegExp(r'retorno[:\s]*(.+?)(?=\n\n|\n(?:queixa|história|historia|exame|hipótese|hipotese|$))', caseSensitive: false, dotAll: true),
      ],
    };

    final result = <String, String>{
      'queixaPrincipal': '',
      'historiaDoenca': '',
      'exameFisico': '',
      'hipoteseDiagnostica': '',
      'conduta': '',
    };

    // Tentar extrair cada seção usando os padrões
    for (var entry in patterns.entries) {
      String? extracted;
      
      for (var pattern in entry.value) {
        final match = pattern.firstMatch(normalized);
        if (match != null && match.groupCount >= 1) {
          extracted = match.group(1)?.trim();
          if (extracted != null && extracted.isNotEmpty) {
            break;
          }
        }
      }
      
      result[entry.key] = extracted ?? '';
    }

    // Se nenhuma seção foi encontrada, tentar dividir por quebras de linha duplas
    // e atribuir baseado em palavras-chave
    if (result.values.every((v) => v.isEmpty)) {
      final sections = normalized.split(RegExp(r'\n\n+'));
      for (var section in sections) {
        section = section.trim();
        if (section.isEmpty) continue;

        final lowerSection = section.toLowerCase();
        
        if (lowerSection.contains('queixa') && result['queixaPrincipal']!.isEmpty) {
          result['queixaPrincipal'] = section;
        } else if ((lowerSection.contains('história') || lowerSection.contains('historia') || lowerSection.contains('hda')) && 
                   result['historiaDoenca']!.isEmpty) {
          result['historiaDoenca'] = section;
        } else if ((lowerSection.contains('exame') || lowerSection.contains('físico') || lowerSection.contains('fisico')) && 
                   result['exameFisico']!.isEmpty) {
          result['exameFisico'] = section;
        } else if ((lowerSection.contains('hipótese') || lowerSection.contains('hipotese') || lowerSection.contains('diagnóstico') || lowerSection.contains('diagnostico')) && 
                   result['hipoteseDiagnostica']!.isEmpty) {
          result['hipoteseDiagnostica'] = section;
        } else if ((lowerSection.contains('conduta') || lowerSection.contains('orientação') || lowerSection.contains('orientacao')) && 
                   result['conduta']!.isEmpty) {
          result['conduta'] = section;
        }
      }
    }

    // Se ainda não encontrou seções, colocar todo o texto na primeira seção (Queixa Principal)
    if (result.values.every((v) => v.isEmpty) && normalized.isNotEmpty) {
      result['queixaPrincipal'] = normalized;
    }

    return result;
  }

  /// Retorna labels formatados para as seções
  static Map<String, String> getSectionLabels() {
    return {
      'queixaPrincipal': 'Queixa Principal',
      'historiaDoenca': 'História da Doença',
      'exameFisico': 'Exame Físico',
      'hipoteseDiagnostica': 'Hipótese Diagnóstica',
      'conduta': 'Conduta',
    };
  }

  /// Retorna ícones para cada seção
  static Map<String, IconData> getSectionIcons() {
    return {
      'queixaPrincipal': Icons.record_voice_over,
      'historiaDoenca': Icons.history,
      'exameFisico': Icons.medical_services,
      'hipoteseDiagnostica': Icons.psychology,
      'conduta': Icons.description,
    };
  }

  /// Formata texto estruturado (ex: "Duração dos Sintomas: ..., Início: ...")
  static String _formatStructuredText(String text) {
    // Substituir vírgulas que separam campos por quebras de linha
    text = text.replaceAllMapped(
      RegExp(r'([^:]+):\s*([^,]+),'),
      (match) => '${match.group(1)}: ${match.group(2)}\n',
    );
    // Último campo (sem vírgula no final)
    text = text.replaceAllMapped(
      RegExp(r'([^:]+):\s*([^,]+)$'),
      (match) => '${match.group(1)}: ${match.group(2)}',
    );
    return text.trim();
  }
}

