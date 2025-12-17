import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/audio_service.dart';
import '../../../data/datasources/clinical_datasource.dart';
import '../../../services/api_service.dart';

class ClinicalRecordingPage extends StatefulWidget {
  const ClinicalRecordingPage({super.key});

  @override
  State<ClinicalRecordingPage> createState() => _ClinicalRecordingPageState();
}

class _ClinicalRecordingPageState extends State<ClinicalRecordingPage> {
  final AudioService _audioService = AudioService();
  final ClinicalDataSource _clinicalDataSource = ClinicalDataSource(ApiService());
  StreamSubscription<Map<String, dynamic>>? _transcriptSubscription;
  
  bool _isRecording = false;
  String _transcript = '';
  String _insights = 'Inicie a conversa para gerar insights automáticos...';
  List<String> _suggestedQuestions = [];
  String? _consultationId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupTranscriptListener();
  }

  void _setupTranscriptListener() {
    _transcriptSubscription = _audioService.transcriptStream?.listen((data) {
      if (mounted) {
        setState(() {
          if (data['transcript'] != null) {
            _transcript = data['transcript'];
          }
          if (data['analysis'] != null && data['shouldAnalyze'] == true) {
            final analysis = data['analysis'];
            _insights = analysis['insights'] ?? _insights;
            _suggestedQuestions = List<String>.from(analysis['suggestedQuestions'] ?? []);
          }
        });
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
        _transcript = '';
        _insights = 'IA conectada. Ouvindo atendimento...';
        _suggestedQuestions = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar gravação: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
        _isRecording = false;
      });

      await _audioService.stopRecording();
      _consultationId = _audioService.consultationId;

      if (_consultationId != null && _transcript.isNotEmpty) {
        // Gerar prontuário final
        try {
          final medicalRecord = await _clinicalDataSource.generateSummary(_consultationId!);
          
          if (mounted) {
            // Navegar para página de detalhes ou mostrar prontuário
            context.go('/clinical/$_consultationId');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao gerar prontuário: $e')),
            );
          }
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao parar gravação: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _transcriptSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: AppColors.mintGreen),
            SizedBox(width: 8),
            Text('Atendimento Inteligente'),
          ],
        ),
        actions: _isRecording
            ? [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.red500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.red500),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: AppColors.red500, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'GRAVANDO',
                        style: TextStyle(
                          color: AppColors.red500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transcription Section
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate800.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, size: 16, color: AppColors.slateLight),
                      SizedBox(width: 8),
                      Text(
                        'TRANSCRIÇÃO EM TEMPO REAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _transcript.isEmpty ? 'Capturando áudio...' : _transcript,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Insights and Questions
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.slate800.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, size: 18, color: AppColors.electricBlue),
                            SizedBox(width: 8),
                            Text(
                              'INSIGHTS CLÍNICOS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _insights,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.slate800.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.purple400.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline, size: 18, color: AppColors.purple400),
                            SizedBox(width: 8),
                            Text(
                              'PERGUNTAS SUGERIDAS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purple400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_suggestedQuestions.isEmpty)
                          const Text(
                            'A IA sugerirá perguntas conforme a consulta avança.',
                            style: TextStyle(
                              color: AppColors.slateLight,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ..._suggestedQuestions.map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $q',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Control Buttons
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_isRecording)
              ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mintGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Finalizar Atendimento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Iniciar Gravação',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

