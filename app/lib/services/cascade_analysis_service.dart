import '../core/constants/api_constants.dart';
import '../data/models/cascade_analysis_model.dart';
import 'api_service.dart';

class CascadeAnalysisService {
  final ApiService _apiService;

  CascadeAnalysisService(this._apiService);

  Future<CascadeAnalysisResult> processCascade(String transcript, {String? doctorNotes, String? consultationId}) async {
    try {
      print('[CascadeAnalysisService] Enviando requisição para process-cascade');
      print('[CascadeAnalysisService] Transcript length: ${transcript.length}');
      if (doctorNotes != null && doctorNotes.isNotEmpty) {
        print('[CascadeAnalysisService] Doctor notes length: ${doctorNotes.length}');
      }
      if (consultationId != null) {
        print('[CascadeAnalysisService] Consultation ID: $consultationId');
      }
      
      final response = await _apiService.post(
        ApiConstants.processCascade,
        data: {
          'transcript': transcript,
          if (doctorNotes != null && doctorNotes.isNotEmpty) 'doctorNotes': doctorNotes,
          if (consultationId != null) 'consultationId': consultationId,
        },
      );

      print('[CascadeAnalysisService] Resposta recebida: ${response.data}');
      
      final result = CascadeAnalysisResult.fromJson(response.data);
      
      print('[CascadeAnalysisService] Resultado parseado:');
      print('  - Summary: ${result.summary.length} chars');
      print('  - Anamnesis: ${result.anamnesis.length} chars');
      print('  - Prescription: ${result.prescription?.length ?? 0} chars');
      print('  - Questions: ${result.suggestedQuestions.length}');
      
      return result;
    } catch (e, stackTrace) {
      print('[CascadeAnalysisService] ERRO ao processar cascata: $e');
      print('[CascadeAnalysisService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

