import 'dart:convert';
import 'medical_record_model.dart';

class ConsultationModel {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? transcript;
  final String? summary;
  final String? anamnesis;
  final String? prescription;
  final String? suggestedMedications;
  final List<String>? suggestedQuestions;
  final String? doctorNotes;
  final List<Map<String, String>>? chatMessages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MedicalRecordModel? medicalRecord;

  ConsultationModel({
    required this.id,
    this.patientId,
    this.patientName,
    this.transcript,
    this.summary,
    this.anamnesis,
    this.prescription,
    this.suggestedMedications,
    this.suggestedQuestions,
    this.doctorNotes,
    this.chatMessages,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    this.medicalRecord,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    // Helper para parsear lista de strings
    List<String>? _parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList().cast<String>();
      }
      if (value is String) {
        try {
          final parsed = jsonDecode(value) as List;
          return parsed.map((e) => e.toString()).toList().cast<String>();
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper para parsear chat messages
    List<Map<String, String>>? _parseChatMessages(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => Map<String, String>.from(e as Map)).toList();
      }
      if (value is String) {
        try {
          final parsed = jsonDecode(value) as List;
          return parsed.map((e) => Map<String, String>.from(e as Map)).toList();
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return ConsultationModel(
      id: json['id'] ?? '',
      patientId: json['patientId'],
      patientName: json['patientName'],
      transcript: json['transcript'],
      summary: json['summary'],
      anamnesis: json['anamnesis'],
      prescription: json['prescription'],
      suggestedMedications: json['suggestedMedications'],
      suggestedQuestions: _parseStringList(json['suggestedQuestions']),
      doctorNotes: json['doctorNotes'],
      chatMessages: _parseChatMessages(json['chatMessages']),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      medicalRecord: json['medicalRecord'] != null
          ? MedicalRecordModel.fromJson(json['medicalRecord'])
          : null,
    );
  }
}

