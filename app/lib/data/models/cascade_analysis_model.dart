class CascadeAnalysisResult {
  final String summary;
  final String anamnesis;
  final String? prescription;
  final String? suggestedMedications;
  final List<String> suggestedQuestions;

  CascadeAnalysisResult({
    required this.summary,
    required this.anamnesis,
    this.prescription,
    this.suggestedMedications,
    required this.suggestedQuestions,
  });

  factory CascadeAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Converter summary
    String summaryText = json['summary']?.toString() ?? '';

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

    // Converter suggestedMedications (pode ser null)
    String? suggestedMedicationsText;
    if (json['suggestedMedications'] != null) {
      if (json['suggestedMedications'] is List) {
        suggestedMedicationsText = (json['suggestedMedications'] as List).join('\n');
      } else {
        suggestedMedicationsText = json['suggestedMedications']?.toString();
      }
    }

    // Converter suggestedQuestions
    List<String> questions = [];
    if (json['suggestedQuestions'] is List) {
      questions = (json['suggestedQuestions'] as List)
          .map((q) => q.toString())
          .toList();
    }

    return CascadeAnalysisResult(
      summary: summaryText,
      anamnesis: anamnesisText,
      prescription: prescriptionText,
      suggestedMedications: suggestedMedicationsText,
      suggestedQuestions: questions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'anamnesis': anamnesis,
      'prescription': prescription,
      'suggestedMedications': suggestedMedications,
      'suggestedQuestions': suggestedQuestions,
    };
  }
}

