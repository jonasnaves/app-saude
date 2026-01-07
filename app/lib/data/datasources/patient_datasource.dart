import 'dart:typed_data';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/patient_model.dart';
import 'package:dio/dio.dart' show FormData, MultipartFile, Options, DioException;

class PatientDataSource {
  final ApiService apiService;

  PatientDataSource(this.apiService);

  /**
   * Lista pacientes com busca e paginação
   */
  Future<Map<String, dynamic>> getPatients({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await apiService.get(
        ApiConstants.patients,
        queryParameters: queryParams,
      );

      return {
        'patients': (response.data['patients'] as List)
            .map((json) => PatientModel.fromJson(json))
            .toList(),
        'total': response.data['total'] as int,
        'page': response.data['page'] as int,
        'limit': response.data['limit'] as int,
      };
    } catch (e) {
      print('[PatientDataSource] Erro ao listar pacientes: $e');
      rethrow;
    }
  }

  /**
   * Obtém um paciente por ID
   */
  Future<PatientModel> getPatient(String id) async {
    try {
      final response = await apiService.get(ApiConstants.patientById(id));
      return PatientModel.fromJson(response.data);
    } catch (e) {
      print('[PatientDataSource] Erro ao obter paciente: $e');
      rethrow;
    }
  }

  /**
   * Cria um novo paciente
   */
  Future<PatientModel> createPatient(PatientModel patient) async {
    try {
      // Converter para JSON, removendo campos calculados
      final json = patient.toJson();
      json.remove('id');
      json.remove('createdAt');
      json.remove('updatedAt');

      print('[PatientDataSource] Criando paciente:');
      print('[PatientDataSource] JSON a ser enviado: ${json.toString()}');
      print('[PatientDataSource] Nome: ${json['name']}');
      print('[PatientDataSource] CPF: ${json['cpf']}');
      print('[PatientDataSource] Email: ${json['email']}');

      final response = await apiService.post(
        ApiConstants.patients,
        data: json,
      );

      print('[PatientDataSource] Resposta recebida: ${response.statusCode}');
      print('[PatientDataSource] Response data: ${response.data}');

      if (response.data == null) {
        throw Exception('Resposta do servidor está vazia');
      }

      return PatientModel.fromJson(response.data);
    } catch (e) {
      print('[PatientDataSource] Erro ao criar paciente: $e');
      print('[PatientDataSource] Tipo do erro: ${e.runtimeType}');
      if (e is DioException) {
        print('[PatientDataSource] Status code: ${e.response?.statusCode}');
        print('[PatientDataSource] Response data: ${e.response?.data}');
        print('[PatientDataSource] Request data: ${e.requestOptions.data}');
      }
      rethrow;
    }
  }

  /**
   * Atualiza um paciente existente
   */
  Future<PatientModel> updatePatient(String id, PatientModel patient) async {
    try {
      // Converter para JSON, removendo campos que não devem ser atualizados
      final json = patient.toJson();
      json.remove('id');
      json.remove('createdAt');
      json.remove('updatedAt');

      final response = await apiService.put(
        ApiConstants.patientById(id),
        data: json,
      );
      return PatientModel.fromJson(response.data);
    } catch (e) {
      print('[PatientDataSource] Erro ao atualizar paciente: $e');
      rethrow;
    }
  }

  /**
   * Exclui um paciente
   */
  Future<void> deletePatient(String id) async {
    try {
      await apiService.delete(ApiConstants.patientById(id));
    } catch (e) {
      print('[PatientDataSource] Erro ao excluir paciente: $e');
      rethrow;
    }
  }

  /**
   * Faz upload de uma foto do paciente
   */
  Future<Map<String, dynamic>> uploadPhoto(
    String patientId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
      });

      final response = await apiService.post(
        ApiConstants.patientPhotos(patientId),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return {
        'photo': response.data['photo'],
        'patient': PatientModel.fromJson(response.data['patient']),
      };
    } catch (e) {
      print('[PatientDataSource] Erro ao fazer upload de foto: $e');
      rethrow;
    }
  }

  /**
   * Exclui uma foto do paciente
   */
  Future<PatientModel> deletePhoto(String patientId, String photoId) async {
    try {
      final response = await apiService.delete(
        ApiConstants.patientPhoto(patientId, photoId),
      );
      return PatientModel.fromJson(response.data['patient']);
    } catch (e) {
      print('[PatientDataSource] Erro ao excluir foto: $e');
      rethrow;
    }
  }

  /**
   * Faz upload de um documento do paciente
   */
  Future<Map<String, dynamic>> uploadDocument(
    String patientId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'document': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await apiService.post(
        ApiConstants.patientDocuments(patientId),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return {
        'document': PatientDocument.fromJson(response.data['document']),
        'patient': PatientModel.fromJson(response.data['patient']),
      };
    } catch (e) {
      print('[PatientDataSource] Erro ao fazer upload de documento: $e');
      rethrow;
    }
  }

  /**
   * Exclui um documento do paciente
   */
  Future<PatientModel> deleteDocument(String patientId, String docId) async {
    try {
      final response = await apiService.delete(
        ApiConstants.patientDocument(patientId, docId),
      );
      return PatientModel.fromJson(response.data['patient']);
    } catch (e) {
      print('[PatientDataSource] Erro ao excluir documento: $e');
      rethrow;
    }
  }
}

