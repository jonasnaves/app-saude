import '../core/constants/api_constants.dart';
import 'api_service.dart';

class IncrementalAnalysis {
  final String anamnesis;
  final String? prescription; // null se não houver prescrição
  final List<String> suggestedQuestions;

  IncrementalAnalysis({
    required this.anamnesis,
    this.prescription,
    required this.suggestedQuestions,
  });

  factory IncrementalAnalysis.fromJson(Map<String, dynamic> json) {
    // Converter anamnesis
    String anamnesisText = '';
    if (json['anamnesis'] is List) {
      anamnesisText = (json['anamnesis'] as List).join('\n');
    } else {
      anamnesisText = json['anamnesis']?.toString() ?? '';
    }

    // Converter prescription (pode ser null)
    String? prescriptionText;
    if (json['prescription'] != null) {
      if (json['prescription'] is List) {
        prescriptionText = (json['prescription'] as List).join('\n');
      } else {
        prescriptionText = json['prescription']?.toString();
      }
    }

    // Converter suggestedQuestions se necessário
    List<String> questions = [];
    if (json['suggestedQuestions'] is List) {
      questions = (json['suggestedQuestions'] as List)
          .map((q) => q.toString())
          .toList();
    }

    return IncrementalAnalysis(
      anamnesis: anamnesisText,
      prescription: prescriptionText,
      suggestedQuestions: questions,
    );
  }
}

class TranscriptionSummary {
  final String anamnesis;
  final String physicalExam;
  final List<String> diagnosisSuggestions;
  final String conduct;

  TranscriptionSummary({
    required this.anamnesis,
    required this.physicalExam,
    required this.diagnosisSuggestions,
    required this.conduct,
  });

  factory TranscriptionSummary.fromJson(Map<String, dynamic> json) {
    return TranscriptionSummary(
      anamnesis: json['anamnesis'] ?? '',
      physicalExam: json['physicalExam'] ?? '',
      diagnosisSuggestions: (json['diagnosisSuggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      conduct: json['conduct'] ?? '',
    );
  }
}

class GeminiAnalysisService {
  final ApiService _apiService;

  GeminiAnalysisService(this._apiService);

  Future<IncrementalAnalysis> getIncrementalAnalysis(
    String transcript,
    String? previousAnamnesis,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.analyzeIncremental,
        data: {
          'transcript': transcript,
          'previousInsights': previousAnamnesis ?? '',
          'consultationId': null, // Será preenchido pelo backend se necessário
        },
      );

      return IncrementalAnalysis.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TranscriptionSummary> getClinicalSummary(String transcript) async {
    try {
      final response = await _apiService.post(
        ApiConstants.generateSummary,
        data: {
          'transcript': transcript,
        },
      );

      return TranscriptionSummary.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

