class MedicalRecordModel {
  final String id;
  final String consultationId;
  final String anamnesis;
  final String physicalExam;
  final List<String> diagnosisSuggestions;
  final String conduct;
  final DateTime createdAt;

  MedicalRecordModel({
    required this.id,
    required this.consultationId,
    required this.anamnesis,
    required this.physicalExam,
    required this.diagnosisSuggestions,
    required this.conduct,
    required this.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'],
      consultationId: json['consultationId'],
      anamnesis: json['anamnesis'],
      physicalExam: json['physicalExam'],
      diagnosisSuggestions: List<String>.from(json['diagnosisSuggestions'] ?? []),
      conduct: json['conduct'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

