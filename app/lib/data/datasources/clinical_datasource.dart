import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/consultation_model.dart';
import '../models/medical_record_model.dart';

class ClinicalDataSource {
  final ApiService apiService;

  ClinicalDataSource(this.apiService);

  Future<Map<String, dynamic>> startRecording({String? patientId, String? anonymousPatientName}) async {
    final response = await apiService.post(
      ApiConstants.startRecording,
      data: {
        if (patientId != null) 'patientId': patientId,
        if (anonymousPatientName != null) 'anonymousPatientName': anonymousPatientName,
      },
    );
    return {
      'consultationId': response.data['consultationId'],
      'patientId': response.data['patientId'],
      'patientName': response.data['patientName'],
    };
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
    
    // O backend retorna apenas os campos do resumo, precisamos adicionar id, consultationId e createdAt
    dynamic medicalRecordData = response.data['medicalRecord'];
    
    // Garantir que medicalRecordData é um Map
    if (medicalRecordData is! Map<String, dynamic>) {
      // Se não for um Map, tentar converter
      if (medicalRecordData is Map) {
        medicalRecordData = Map<String, dynamic>.from(medicalRecordData);
      } else {
        throw Exception('Formato de resposta inválido do backend: medicalRecord não é um Map');
      }
    }
    
    final fullRecord = Map<String, dynamic>.from(medicalRecordData);
    fullRecord['id'] = consultationId; // Usar consultationId como id temporário
    fullRecord['consultationId'] = consultationId;
    fullRecord['createdAt'] = DateTime.now().toIso8601String();
    
    return MedicalRecordModel.fromJson(fullRecord);
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
    try {
      print('[ClinicalDataSource] Buscando lista de consultas...');
      final response = await apiService.get(ApiConstants.consultations);
      print('[ClinicalDataSource] Resposta recebida: ${response.data.runtimeType}');
      
      // O backend retorna { consultations: [...], total: ..., page: ..., limit: ... }
      if (response.data is Map && response.data['consultations'] != null) {
        final consultationsList = response.data['consultations'] as List;
        print('[ClinicalDataSource] Encontradas ${consultationsList.length} consultas');
        return consultationsList
            .map((json) {
              try {
                return ConsultationModel.fromJson(json);
              } catch (e) {
                print('[ClinicalDataSource] Erro ao parsear consulta: $e');
                return null;
              }
            })
            .whereType<ConsultationModel>()
            .toList();
      }
      // Fallback: se retornar array direto
      if (response.data is List) {
        print('[ClinicalDataSource] Resposta é array direto com ${(response.data as List).length} itens');
        return (response.data as List)
            .map((json) {
              try {
                return ConsultationModel.fromJson(json);
              } catch (e) {
                print('[ClinicalDataSource] Erro ao parsear consulta: $e');
                return null;
              }
            })
            .whereType<ConsultationModel>()
            .toList();
      }
      print('[ClinicalDataSource] Formato de resposta não reconhecido');
      return [];
    } catch (e, stackTrace) {
      print('[ClinicalDataSource] Erro ao buscar consultas: $e');
      print('[ClinicalDataSource] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ConsultationModel> getConsultation(String id) async {
    final response = await apiService.get('/clinical/consultations/$id');
    return ConsultationModel.fromJson(response.data);
  }

  Future<void> saveMedicalRecordPartial({
    required String consultationId,
    String? patientId,
    String? transcript,
    String? summary,
    String? anamnesis,
    String? prescription,
    String? suggestedMedications,
    List<String>? suggestedQuestions,
    String? doctorNotes,
    List<Map<String, String>>? chatMessages,
  }) async {
    final Map<String, dynamic> data = {
      'consultationId': consultationId,
    };
    
    // Adicionar campos ao map - em Dart, parâmetros opcionais não passados são null
    // Mas precisamos enviar explicitamente null para o backend limpar campos
    // Por isso, vamos sempre adicionar os campos se foram passados como parâmetro
    // A verificação será feita no backend (undefined vs null)
    
    // Para distinguir entre "não passado" e "null", vamos usar uma convenção:
    // Se o campo foi passado explicitamente (mesmo que null), adicionar ao map
    // Como não temos undefined em Dart, vamos sempre adicionar se o parâmetro existe
    
    // Solução: usar um Map opcional ou sempre enviar todos os campos
    // A solução mais prática: sempre enviar o campo se ele foi passado
    // Como não podemos distinguir facilmente, vamos enviar todos os campos que não são null
    // E para campos que queremos limpar, vamos passar uma string vazia ou null explicitamente
    
    // Por enquanto, vamos enviar apenas campos não-null
    // O backend vai atualizar apenas os campos fornecidos
    if (patientId != null) {
      data['patientId'] = patientId;
    }
    if (transcript != null) {
      data['transcript'] = transcript;
    }
    if (summary != null) {
      data['summary'] = summary;
    }
    if (anamnesis != null) {
      data['anamnesis'] = anamnesis;
    }
    if (prescription != null) {
      data['prescription'] = prescription;
    }
    if (suggestedMedications != null) {
      data['suggestedMedications'] = suggestedMedications;
    }
    if (suggestedQuestions != null) {
      data['suggestedQuestions'] = suggestedQuestions;
    }
    if (doctorNotes != null) {
      data['doctorNotes'] = doctorNotes;
    }
    if (chatMessages != null) {
      data['chatMessages'] = chatMessages;
    }
    
    final fields = data.keys.where((k) => k != 'consultationId').toList();
    print('[ClinicalDataSource] Salvando prontuário parcial: consultationId=$consultationId, fieldsCount=${fields.length}, fields=$fields');
    
    try {
      await apiService.post(
        ApiConstants.saveMedicalRecord,
        data: data,
      );
      print('[ClinicalDataSource] Prontuário salvo com sucesso');
    } catch (e) {
      print('[ClinicalDataSource] Erro ao salvar prontuário: $e');
      rethrow;
    }
  }

  Future<void> finishConsultation(String consultationId) async {
    await apiService.post(
      ApiConstants.finishConsultation,
      data: {'consultationId': consultationId},
    );
  }

  Future<void> resumeConsultation(String consultationId) async {
    await apiService.post(
      ApiConstants.resumeConsultation,
      data: {'consultationId': consultationId},
    );
  }
}

