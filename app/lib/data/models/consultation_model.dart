import 'medical_record_model.dart';

class ConsultationModel {
  final String id;
  final String? patientName;
  final String? transcript;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final MedicalRecordModel? medicalRecord;

  ConsultationModel({
    required this.id,
    this.patientName,
    this.transcript,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    this.medicalRecord,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      patientName: json['patientName'],
      transcript: json['transcript'],
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      medicalRecord: json['medicalRecord'] != null
          ? MedicalRecordModel.fromJson(json['medicalRecord'])
          : null,
    );
  }
}

