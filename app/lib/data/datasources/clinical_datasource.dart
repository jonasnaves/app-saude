import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/consultation_model.dart';
import '../models/medical_record_model.dart';

class ClinicalDataSource {
  final ApiService apiService;

  ClinicalDataSource(this.apiService);

  Future<String> startRecording() async {
    final response = await apiService.post(ApiConstants.startRecording);
    return response.data['consultationId'];
  }

  Future<Map<String, dynamic>> analyzeIncremental(
    String transcript,
    String? previousInsights,
  ) async {
    final response = await apiService.post(
      ApiConstants.analyzeIncremental,
      data: {
        'transcript': transcript,
        'previousInsights': previousInsights ?? '',
      },
    );
    return response.data;
  }

  Future<MedicalRecordModel> generateSummary(String consultationId) async {
    final response = await apiService.post(
      ApiConstants.generateSummary,
      data: {
        'consultationId': consultationId,
      },
    );
    return MedicalRecordModel.fromJson(response.data['medicalRecord']);
  }

  Future<void> updateTranscript(String consultationId, String transcript) async {
    await apiService.post(
      ApiConstants.transcribe,
      data: {
        'consultationId': consultationId,
        'transcript': transcript,
      },
    );
  }

  Future<List<ConsultationModel>> getConsultations() async {
    final response = await apiService.get(ApiConstants.consultations);
    return (response.data as List)
        .map((json) => ConsultationModel.fromJson(json))
        .toList();
  }

  Future<ConsultationModel> getConsultation(String id) async {
    final response = await apiService.get('${ApiConstants.consultations}/$id');
    return ConsultationModel.fromJson(response.data);
  }
}

