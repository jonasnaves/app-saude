import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'whisper_transcription_service.dart';
import 'gemini_analysis_service.dart';
import 'cascade_analysis_service.dart';
import 'api_service.dart';
import '../data/datasources/clinical_datasource.dart';

class AudioService {
  final WhisperTranscriptionService _transcription = WhisperTranscriptionService();
  final GeminiAnalysisService _analysis = GeminiAnalysisService(ApiService());
  final CascadeAnalysisService _cascadeAnalysis = CascadeAnalysisService(ApiService());
  
  StreamController<Map<String, dynamic>>? _transcriptController;
  StreamSubscription<String>? _transcriptionSubscription;
  Timer? _analysisCheckTimer;
  
  bool _isRecording = false;
  String _fullTranscript = ''; // Transcrição completa persistente
  String _currentAnamnesis = '';
  String? _currentPrescription;
  List<String> _currentSuggestedQuestions = [];
  String _doctorNotes = ''; // Notas do médico
  
  // Controle de frequência de análise: 10 segundos E 200 caracteres
  DateTime? _lastAnalysisTime;
  int _lastAnalysisLength = 0;
  static const int _analysisCharThreshold = 200;
  static const int _analysisTimeThresholdSeconds = 10;
  
  // Controle de cascata: executa quando transcrição atinge tamanho mínimo
  DateTime? _lastCascadeTime;
  int _lastCascadeLength = 0;
  static const int _cascadeCharThreshold = 200; // Mesmo threshold que análise incremental
  static const int _cascadeTimeThresholdSeconds = 10; // Mesmo threshold que análise incremental
  bool _isProcessingCascade = false;
  
  String? _consultationId;
  String? _patientId;
  String? _patientName;

  bool get isRecording => _isRecording;
  Stream<Map<String, dynamic>>? get transcriptStream => _transcriptController?.stream;
  String? get consultationId => _consultationId;
  String? get patientId => _patientId;
  String? get patientName => _patientName;
  String get fullTranscript => _fullTranscript;
  
  // Método para atualizar notas do médico
  void updateDoctorNotes(String notes) {
    _doctorNotes = notes;
  }

  Future<void> startRecording({String? patientId, String? anonymousPatientName, String? existingConsultationId}) async {
    if (_isRecording) return;

    if (!kIsWeb) {
      throw Exception('Transcrição em tempo real disponível apenas na web');
    }

    _isRecording = true;
    // Não limpar _fullTranscript se estiver retomando uma consulta existente
    if (existingConsultationId == null) {
      _fullTranscript = '';
      _currentAnamnesis = '';
      _currentPrescription = null;
      _currentSuggestedQuestions = [];
    }
    _lastAnalysisLength = 0;
    _lastAnalysisTime = DateTime.now();
    _lastCascadeLength = 0;
    _lastCascadeTime = DateTime.now();
    _isProcessingCascade = false;
    _patientId = patientId;
    _patientName = anonymousPatientName;

    _transcriptController = StreamController<Map<String, dynamic>>.broadcast();

    // Se já tem uma consulta existente, usar ela. Caso contrário, criar nova
    if (existingConsultationId != null) {
      _consultationId = existingConsultationId;
      print('[AudioService] Retomando consulta existente: $existingConsultationId');
      // Atualizar patientId mesmo ao retomar, caso tenha mudado
      if (patientId != null) {
        _patientId = patientId;
      }
      if (anonymousPatientName != null) {
        _patientName = anonymousPatientName;
      }
    } else {
      // Iniciar consulta no backend com patientId primeiro
      print('[AudioService] Criando nova consulta - PatientId: $patientId, PatientName: $anonymousPatientName');
      final ClinicalDataSource clinicalDataSource = ClinicalDataSource(ApiService());
      final result = await clinicalDataSource.startRecording(
        patientId: patientId,
        anonymousPatientName: anonymousPatientName,
      );
      _consultationId = result['consultationId'];
      _patientId = result['patientId'];
      _patientName = result['patientName'];
      print('[AudioService] Nova consulta criada: $_consultationId, PatientId retornado: $_patientId, PatientName retornado: $_patientName');
    }
    
    // Iniciar transcrição Whisper - passar consultationId para evitar duplicação
    await _transcription.startRecording(consultationId: _consultationId);

    // Escutar transcrições (sempre recebe transcrição completa acumulada)
    _transcriptionSubscription = _transcription.transcriptStream?.listen(
      (transcript) {
        _fullTranscript = transcript;
        
        // Enviar transcrição completa ao stream
        _transcriptController?.add({
          'type': 'transcript',
          'transcript': _fullTranscript, // Sempre a transcrição completa
          'analysis': null,
          'shouldAnalyze': false,
        });

        // Verificar condições para análise incremental (10s E 200 chars)
        _checkAnalysisConditions();
        
        // Verificar condições para cascata (10s E 200 chars)
        _checkCascadeConditions();
      },
      onError: (error) {
        _transcriptController?.addError(error);
      },
    );

    // Iniciar timer para verificar condições de análise a cada segundo
    _analysisCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording) {
        _checkAnalysisConditions();
      }
    });
  }

  void _checkAnalysisConditions() {
    if (!_isRecording || _fullTranscript.isEmpty) return;

    final now = DateTime.now();
    final timeSinceLastAnalysis = _lastAnalysisTime != null
        ? now.difference(_lastAnalysisTime!).inSeconds
        : _analysisTimeThresholdSeconds;
    final charsSinceLastAnalysis = _fullTranscript.length - _lastAnalysisLength;

    // Verificar se AMBAS condições são atendidas
    final timeCondition = timeSinceLastAnalysis >= _analysisTimeThresholdSeconds;
    final charCondition = charsSinceLastAnalysis >= _analysisCharThreshold;

    if (timeCondition && charCondition) {
      _triggerIncrementalAnalysis(_fullTranscript);
    }
  }

  Future<void> _triggerIncrementalAnalysis(String transcript) async {
    try {
      // Verificar se ainda está gravando antes de fazer a análise
      if (!_isRecording || _transcriptController == null) {
        return;
      }

      final analysis = await _analysis.getIncrementalAnalysis(
        transcript,
        _currentAnamnesis.isEmpty ? null : _currentAnamnesis,
      );

      // Atualizar insights
      _currentAnamnesis = analysis.anamnesis;
      _currentPrescription = analysis.prescription;
      _currentSuggestedQuestions = analysis.suggestedQuestions;

      final streamData = {
        'type': 'transcript',
        'transcript': _fullTranscript, // Sempre a transcrição completa
        'analysis': {
          'anamnesis': analysis.anamnesis,
          'prescription': analysis.prescription,
          'suggestedQuestions': analysis.suggestedQuestions,
        },
        'shouldAnalyze': true,
      };

      _transcriptController?.add(streamData);
      
      // Atualizar timestamps e comprimento após análise completar
      _lastAnalysisTime = DateTime.now();
      _lastAnalysisLength = transcript.length;
      
    } catch (e) {
      // Em caso de erro, ainda atualizamos os timestamps
      // para evitar tentativas repetidas com o mesmo texto
      _lastAnalysisTime = DateTime.now();
      _lastAnalysisLength = transcript.length;
      _transcriptController?.addError('Erro na análise incremental: $e');
    }
  }

  void _checkCascadeConditions() {
    if (!_isRecording || _fullTranscript.isEmpty || _isProcessingCascade) return;

    final now = DateTime.now();
    final timeSinceLastCascade = _lastCascadeTime != null
        ? now.difference(_lastCascadeTime!).inSeconds
        : _cascadeTimeThresholdSeconds;
    final charsSinceLastCascade = _fullTranscript.length - _lastCascadeLength;

    // Verificar se AMBAS condições são atendidas
    final timeCondition = timeSinceLastCascade >= _cascadeTimeThresholdSeconds;
    final charCondition = charsSinceLastCascade >= _cascadeCharThreshold;

    print('[AudioService] Verificando condições de cascata: time=${timeSinceLastCascade}s (>=${_cascadeTimeThresholdSeconds}s), chars=$charsSinceLastCascade (>=${_cascadeCharThreshold})');
    
    if (timeCondition && charCondition) {
      print('[AudioService] Condições atendidas! Disparando cascata...');
      _triggerCascadeAnalysis(_fullTranscript, doctorNotes: _doctorNotes.isNotEmpty ? _doctorNotes : null);
    }
  }

  Future<void> _triggerCascadeAnalysis(String transcript, {String? doctorNotes}) async {
    try {
      // Verificar se ainda está gravando antes de fazer a análise
      if (!_isRecording || _transcriptController == null || _isProcessingCascade) {
        print('[AudioService] Cascata não executada: isRecording=$_isRecording, controller=${_transcriptController != null}, processing=$_isProcessingCascade');
        return;
      }

      print('[AudioService] Iniciando análise em cascata. Transcript length: ${transcript.length}');
      if (doctorNotes != null && doctorNotes.isNotEmpty) {
        print('[AudioService] Incluindo notas do médico no contexto');
      }
      _isProcessingCascade = true;

      // Processar através de todos os agentes em cascata (incluindo notas do médico)
      final cascadeResult = await _cascadeAnalysis.processCascade(
        transcript,
        doctorNotes: doctorNotes,
        consultationId: _consultationId,
      );
      
      print('[AudioService] Cascata concluída:');
      print('  - Summary: ${cascadeResult.summary.length} chars');
      print('  - Anamnesis: ${cascadeResult.anamnesis.length} chars');
      print('  - Prescription: ${cascadeResult.prescription?.length ?? 0} chars');
      print('  - Suggested Medications: ${cascadeResult.suggestedMedications?.length ?? 0} chars');
      print('  - Questions: ${cascadeResult.suggestedQuestions.length}');

      // Enviar resultados da cascata ao stream
      final streamData = {
        'type': 'cascade',
        'transcript': _fullTranscript,
        'cascade': {
          'summary': cascadeResult.summary,
          'anamnesis': cascadeResult.anamnesis,
          'prescription': cascadeResult.prescription,
          'suggestedMedications': cascadeResult.suggestedMedications,
          'suggestedQuestions': cascadeResult.suggestedQuestions,
        },
      };

      print('[AudioService] Enviando dados da cascata para o stream');
      _transcriptController?.add(streamData);
      
      // Atualizar timestamps e comprimento após cascata completar
      _lastCascadeTime = DateTime.now();
      _lastCascadeLength = transcript.length;
      _isProcessingCascade = false;
      
    } catch (e, stackTrace) {
      print('[AudioService] ERRO na análise em cascata: $e');
      print('[AudioService] Stack trace: $stackTrace');
      // Em caso de erro, ainda atualizamos os timestamps
      // para evitar tentativas repetidas com o mesmo texto
      _lastCascadeTime = DateTime.now();
      _lastCascadeLength = transcript.length;
      _isProcessingCascade = false;
      _transcriptController?.addError('Erro na análise em cascata: $e');
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _analysisCheckTimer?.cancel();
    _analysisCheckTimer = null;
    _transcriptionSubscription?.cancel();
    _transcriptionSubscription = null;
    await _transcription.stopRecording();
    
    await _transcriptController?.close();
    _transcriptController = null;
    
    _fullTranscript = '';
    _currentAnamnesis = '';
    _currentPrescription = null;
    _currentSuggestedQuestions = [];
    _lastAnalysisLength = 0;
    _lastAnalysisTime = null;
    _lastCascadeLength = 0;
    _lastCascadeTime = null;
    _isProcessingCascade = false;
  }

  Future<void> dispose() async {
    await stopRecording();
    _transcription.dispose();
    _analysisCheckTimer?.cancel();
  }
}
