class MedicalRecordModel {
  final String id;
  final String consultationId;
  final String? anamnesis;
  final String? physicalExam;
  final List<String>? diagnosisSuggestions;
  final String? conduct;
  final DateTime createdAt;

  MedicalRecordModel({
    required this.id,
    required this.consultationId,
    this.anamnesis,
    this.physicalExam,
    this.diagnosisSuggestions,
    this.conduct,
    required this.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    // Helper para converter qualquer valor para String?
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is Map) return null; // Se for um Map, retornar null ao invés de causar erro
      return value.toString();
    }
    
    // Helper para converter lista
    List<String>? _toListOrNull(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList().cast<String>();
      }
      return null;
    }
    
    return MedicalRecordModel(
      id: json['id']?.toString() ?? '',
      consultationId: json['consultationId']?.toString() ?? '',
      anamnesis: _toStringOrNull(json['anamnesis']),
      physicalExam: _toStringOrNull(json['physicalExam']),
      diagnosisSuggestions: _toListOrNull(json['diagnosisSuggestions']),
      conduct: _toStringOrNull(json['conduct']),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now())
          : DateTime.now(),
    );
  }
}

