import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_service.dart';
import '../../../data/datasources/clinical_datasource.dart';
import '../../../services/api_service.dart';
import '../../../utils/text_formatter.dart';
import '../../../utils/clipboard_service.dart';
import '../../../utils/pdf_generator.dart';
import '../../../utils/anamnesis_parser.dart';
import '../../../widgets/modern_recording_button.dart';
import '../../../widgets/anamnesis_section_card.dart';
import '../../widgets/patient_selector_widget.dart';

class ClinicalRecordingPage extends StatefulWidget {
  final String? consultationId;
  
  const ClinicalRecordingPage({super.key, this.consultationId});

  @override
  State<ClinicalRecordingPage> createState() => _ClinicalRecordingPageState();
}

class _ClinicalRecordingPageState extends State<ClinicalRecordingPage> {
  final AudioService _audioService = AudioService();
  final ClinicalDataSource _clinicalDataSource = ClinicalDataSource(ApiService());
  StreamSubscription<Map<String, dynamic>>? _transcriptSubscription;
  
  bool _isRecording = false;
  String _transcript = '';
  String _anamnesis = 'Inicie a conversa para gerar análise automática...';
  String? _prescription;
  List<String> _suggestedQuestions = [];
  
  // Resultados da cascata de agentes
  String _cascadeSummary = '';
  String _cascadeAnamnesis = '';
  String? _cascadePrescription;
  String? _cascadeSuggestedMedications;
  List<String> _cascadeSuggestedQuestions = [];
  
  // Notas do médico e chat com IA
  String _doctorNotes = '';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  List<Map<String, String>> _chatMessages = []; // [{role: 'user'|'assistant', content: '...'}]
  bool _isSendingChatMessage = false;
  
  String? _consultationId;
  String? _patientId;
  String? _patientName;
  bool _isProcessing = false;
  bool _isConsultationFinished = false;
  final ScrollController _transcriptScrollController = ScrollController();
  
  // Auto-save com debounce
  Timer? _autoSaveTimer;
  static const Duration _autoSaveDebounce = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    // Se consultationId fornecido e válido (não é "recording"), carregar consulta existente
    if (widget.consultationId != null && 
        widget.consultationId!.isNotEmpty && 
        widget.consultationId != 'recording') {
      _loadExistingConsultation(widget.consultationId!);
    }
  }
  
  // Carregar consulta existente
  Future<void> _loadExistingConsultation(String consultationId) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final consultation = await _clinicalDataSource.getConsultation(consultationId);
      
      if (mounted) {
        setState(() {
          _consultationId = consultation.id;
          _patientId = consultation.patientId;
          _patientName = consultation.patientName;
          _isConsultationFinished = consultation.endedAt != null;
          
          // Carregar todos os campos da consulta
          _transcript = consultation.transcript ?? '';
          _cascadeSummary = consultation.summary ?? '';
          _cascadeAnamnesis = consultation.anamnesis ?? '';
          _cascadePrescription = consultation.prescription;
          _cascadeSuggestedMedications = consultation.suggestedMedications;
          _cascadeSuggestedQuestions = consultation.suggestedQuestions ?? [];
          _doctorNotes = consultation.doctorNotes ?? '';
          _chatMessages = consultation.chatMessages != null 
              ? List<Map<String, String>>.from(
                  consultation.chatMessages!.map((msg) => Map<String, String>.from(msg))
                )
              : [];
          
          // Preencher controllers
          _notesController.text = _doctorNotes;
          
          // Se tiver medicalRecord, também carregar (pode ter dados adicionais)
          if (consultation.medicalRecord != null) {
            final record = consultation.medicalRecord!;
            // Se anamnese do medicalRecord for mais completa, usar ela
            if (record.anamnesis != null && record.anamnesis!.isNotEmpty) {
              _cascadeAnamnesis = record.anamnesis!;
            }
          }
          
          _isProcessing = false;
        });
        
        // Sincronizar com AudioService se necessário
        if (!_isConsultationFinished) {
          // Se o audioService não tem consultationId ou é diferente, atualizar
          if (_audioService.consultationId != consultationId) {
            // Não precisamos fazer nada, o audioService será atualizado quando iniciar gravação
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar consulta: $e')),
        );
      }
    }
  }

  void _setupTranscriptListener() {
    _transcriptSubscription = _audioService.transcriptStream?.listen((data) {
      print('[UI] Dados recebidos do stream: type=${data['type']}, hasTranscript=${data['transcript'] != null}, hasAnalysis=${data['analysis'] != null}, hasCascade=${data['cascade'] != null}');
      
      if (mounted) {
        setState(() {
          if (data['transcript'] != null) {
            _transcript = data['transcript'] as String;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_transcriptScrollController.hasClients) {
                _transcriptScrollController.animateTo(
                  _transcriptScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            // Trigger auto-save após mudança de transcript
            _triggerAutoSave();
          }
          
          if (data['analysis'] != null && data['shouldAnalyze'] == true) {
            final analysis = data['analysis'] as Map<String, dynamic>;
            _anamnesis = analysis['anamnesis'] as String? ?? _anamnesis;
            _prescription = analysis['prescription'] as String?;
            _suggestedQuestions = List<String>.from(analysis['suggestedQuestions'] ?? []);
            print('[UI] Análise incremental atualizada');
            // Trigger auto-save após mudança de análise
            _triggerAutoSave();
          }
          
          if (data['type'] == 'cascade' && data['cascade'] != null) {
            final cascade = data['cascade'] as Map<String, dynamic>;
            print('[UI] ===== RECEBENDO DADOS DA CASCATA =====');
            print('[UI] Cascade data: $cascade');
            _cascadeSummary = cascade['summary'] as String? ?? '';
            _cascadeAnamnesis = cascade['anamnesis'] as String? ?? '';
            _cascadePrescription = cascade['prescription'] as String?;
            _cascadeSuggestedMedications = cascade['suggestedMedications'] as String?;
            _cascadeSuggestedQuestions = List<String>.from(cascade['suggestedQuestions'] ?? []);
            print('[UI] Cascade Summary: ${_cascadeSummary.length} chars');
            print('[UI] Cascade Anamnesis: ${_cascadeAnamnesis.length} chars');
            print('[UI] Cascade Prescription: ${_cascadePrescription?.length ?? 0} chars');
            print('[UI] Cascade Suggested Medications: ${_cascadeSuggestedMedications?.length ?? 0} chars');
            print('[UI] Cascade Questions: ${_cascadeSuggestedQuestions.length}');
            print('[UI] ========================================');
            // Trigger auto-save após mudança de cascade
            _triggerAutoSave();
          }
        });
      }
    }, onError: (error) {
      print('[UI] Erro no stream: $error');
    });
  }

  bool _isStartingRecording = false; // Flag para evitar chamadas duplicadas

  Future<void> _startRecording() async {
    // Prevenir chamadas duplicadas
    if (_isStartingRecording || _isRecording) {
      print('[StartRecording] Já está iniciando ou gravando, ignorando chamada duplicada');
      return;
    }

    // Se ainda não tem paciente selecionado, mostrar seletor
    if (_patientId == null && _patientName == null) {
      showDialog(
        context: context,
        builder: (context) => PatientSelectorWidget(
          onPatientSelected: (patientId, anonymousName) {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
            // Atualizar estado e iniciar gravação após fechar diálogo
            setState(() {
              _patientId = patientId;
              _patientName = anonymousName;
            });
            // Aguardar um frame para garantir que o estado foi atualizado
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _doStartRecording();
            });
          },
        ),
      );
      return;
    }
    
    _doStartRecording();
  }

  Future<void> _doStartRecording() async {
    // Prevenir chamadas duplicadas
    if (_isStartingRecording || _isRecording) {
      print('[DoStartRecording] Já está iniciando ou gravando, ignorando chamada duplicada');
      return;
    }

    try {
      _isStartingRecording = true;
      print('[DoStartRecording] Iniciando gravação - PatientId: $_patientId, PatientName: $_patientName, ExistingConsultationId: $_consultationId');
      
      // Se já tem uma consulta em andamento, usar ela. Caso contrário, criar nova
      await _audioService.startRecording(
        patientId: _patientId, 
        anonymousPatientName: _patientName,
        existingConsultationId: _consultationId, // Passar consultationId existente se houver
      );
      _setupTranscriptListener();
      
      if (mounted) {
        setState(() {
          _isRecording = true;
          _isStartingRecording = false;
          // Não limpar dados se estiver retomando uma consulta existente
          if (_consultationId == null) {
            _transcript = '';
            _anamnesis = 'IA conectada. Analisando atendimento...';
            _prescription = null;
            _suggestedQuestions = [];
            _cascadeSummary = '';
            _cascadeAnamnesis = '';
            _cascadePrescription = null;
            _cascadeSuggestedMedications = null;
            _cascadeSuggestedQuestions = [];
          }
          _consultationId = _audioService.consultationId;
          _patientId = _audioService.patientId;
          _patientName = _audioService.patientName;
        });
        
        // Salvar patientId imediatamente após criar consulta
        if (_consultationId != null && _patientId != null) {
          print('[DoStartRecording] Salvando patientId imediatamente após criar consulta');
          _triggerAutoSave();
        }
      }
    } catch (e) {
      _isStartingRecording = false;
      if (mounted) {
        setState(() {
          _isStartingRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar gravação: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isStartingRecording = false; // Resetar flag
      });

      await _audioService.stopRecording();
      _consultationId = _audioService.consultationId;
      
      // Salvar dados finais quando parar a gravação (incluindo patientId)
      if (_consultationId != null) {
        print('[StopRecording] Salvando dados finais da consulta...');
        print('[StopRecording] PatientId: $_patientId, PatientName: $_patientName');
        _triggerAutoSave();
        // Aguardar um pouco para garantir que o auto-save seja executado
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Não navegar, apenas parar gravação
      // Usuário pode retomar gravação ou finalizar consulta quando quiser
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isStartingRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao parar gravação: $e')),
        );
      }
    }
  }
  
  // Finalizar consulta
  Future<void> _finishConsultation() async {
    if (_consultationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma consulta em andamento')),
      );
      return;
    }
    
    try {
      setState(() {
        _isProcessing = true;
      });
      
      await _clinicalDataSource.finishConsultation(_consultationId!);
      
      if (mounted) {
        setState(() {
          _isConsultationFinished = true;
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Consulta finalizada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar para página de detalhes
        context.go('/clinical/$_consultationId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar consulta: $e')),
        );
      }
    }
  }

  Future<void> _copyAll() async {
    final texts = <String>[];
    if (_cascadeSummary.isNotEmpty) {
      texts.add('RESUMO CLÍNICO\n\n${_cascadeSummary}');
    }
    if (_cascadeAnamnesis.isNotEmpty) {
      texts.add('ANAMNESE\n\n${_cascadeAnamnesis}');
    }
    if (_cascadePrescription != null && _cascadePrescription!.isNotEmpty) {
      texts.add('PRESCRIÇÃO\n\n${_cascadePrescription}');
    }
    if (_cascadeSuggestedQuestions.isNotEmpty) {
      texts.add('PERGUNTAS SUGERIDAS\n\n${_cascadeSuggestedQuestions.join('\n• ')}');
    }
    
    if (texts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum conteúdo para copiar')),
      );
      return;
    }
    
    await ClipboardService.copyMultipleToClipboard(texts, context);
  }

  Future<void> _downloadPDF() async {
    if (_cascadeSummary.isEmpty && _cascadeAnamnesis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum conteúdo disponível para gerar PDF')),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final pdfBytes = await PDFGenerator.generateConsultationPDF(
        summary: _cascadeSummary,
        anamnesis: _cascadeAnamnesis,
        prescription: _cascadePrescription,
        consultationId: _consultationId,
      );

      // Download no navegador
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'consulta_${_consultationId ?? DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Para mobile, usar printing
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF gerado e baixado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _transcriptSubscription?.cancel();
    _transcriptScrollController.dispose();
    _notesController.dispose();
    _chatController.dispose();
    _audioService.dispose();
    super.dispose();
  }
  
  // Salvar notas do médico
  void _saveDoctorNotes() {
    setState(() {
      _doctorNotes = _notesController.text;
    });
    // Atualizar notas no AudioService para serem incluídas no contexto dos agentes
    _audioService.updateDoctorNotes(_doctorNotes);
    // Trigger auto-save
    _triggerAutoSave();
  }
  
  // Trigger do debounce para salvamento automático
  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDebounce, () {
      _autoSaveMedicalRecord();
    });
  }
  
  // Salvar prontuário automaticamente
  Future<void> _autoSaveMedicalRecord() async {
    // Verificar se tem consultationId
    if (_consultationId == null) {
      print('[AutoSave] ConsultationId não disponível, pulando salvamento');
      return;
    }
    
    try {
      print('[AutoSave] Iniciando salvamento automático...');
      print('[AutoSave] PatientId: $_patientId, PatientName: $_patientName');
      await _clinicalDataSource.saveMedicalRecordPartial(
        consultationId: _consultationId!,
        patientId: _patientId, // Incluir patientId no auto-save
        transcript: _transcript.isNotEmpty ? _transcript : null,
        summary: _cascadeSummary.isNotEmpty ? _cascadeSummary : null,
        anamnesis: _cascadeAnamnesis.isNotEmpty ? _cascadeAnamnesis : null,
        prescription: _cascadePrescription,
        suggestedMedications: _cascadeSuggestedMedications,
        suggestedQuestions: _cascadeSuggestedQuestions.isNotEmpty ? _cascadeSuggestedQuestions : null,
        doctorNotes: _doctorNotes.isNotEmpty ? _doctorNotes : null,
        chatMessages: _chatMessages.isNotEmpty ? _chatMessages : null,
      );
      // Log silencioso para debug
      print('[AutoSave] Prontuário salvo automaticamente com sucesso');
    } catch (e, stackTrace) {
      // Erro silencioso - não interrompe o fluxo do usuário, mas log detalhado
      print('[AutoSave] Erro ao salvar prontuário: $e');
      print('[AutoSave] Stack trace: $stackTrace');
    }
  }
  
  // Enviar mensagem no chat com IA
  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _isSendingChatMessage) return;
    
    final userMessage = _chatController.text.trim();
    _chatController.clear();
    
    setState(() {
      _chatMessages.add({'role': 'user', 'content': userMessage});
      _isSendingChatMessage = true;
    });
    // Trigger auto-save após adicionar mensagem do usuário
    _triggerAutoSave();
    
    try {
      // Chamar endpoint de chat com IA
      final response = await ApiService().post(
        '/clinical/chat',
        data: {
          'message': userMessage,
          'context': {
            'transcript': _transcript,
            'summary': _cascadeSummary,
            'anamnesis': _cascadeAnamnesis,
            'prescription': _cascadePrescription ?? '',
            'notes': _doctorNotes,
          },
        },
      );
      
      final assistantMessage = response.data['response'] as String? ?? 'Erro ao obter resposta';
      
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': assistantMessage});
        _isSendingChatMessage = false;
      });
      // Trigger auto-save após adicionar mensagem do assistente
      _triggerAutoSave();
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Erro ao comunicar com a IA. Tente novamente.',
        });
        _isSendingChatMessage = false;
      });
      // Trigger auto-save mesmo em caso de erro
      _triggerAutoSave();
    }
  }

  // Construir grid de conteúdo responsivo
  Widget _buildContentGrid(int crossAxisCount, double maxWidth) {
    final anamnesisText = _cascadeAnamnesis.isNotEmpty ? _cascadeAnamnesis : _anamnesis;
    final anamnesisSections = AnamnesisParser.parseAnamnesisSections(anamnesisText);
    final sectionLabels = AnamnesisParser.getSectionLabels();
    final sectionIcons = AnamnesisParser.getSectionIcons();
    final sectionColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    
    // Widget da transcrição (sempre ocupa largura total)
    final transcriptCard = _buildMinimalCard(
      title: 'Transcrição',
      icon: Icons.description,
      accentColor: AppColors.textPrimary,
      onCopy: _transcript.isNotEmpty
          ? () => ClipboardService.copyToClipboard(_transcript, context)
          : null,
      content: Container(
        constraints: const BoxConstraints(minHeight: 200),
        child: SingleChildScrollView(
          controller: _transcriptScrollController,
          child: Text(
            _transcript.isEmpty
                ? 'Aguardando transcrição...'
                : _transcript,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
    
    // Lista de widgets das seções (sem transcrição)
    final sections = <Widget>[];
    
    // Resumo
    if (_cascadeSummary.isNotEmpty) {
      sections.add(
        _buildMinimalCard(
          title: 'Resumo Clínico',
          icon: Icons.summarize,
          accentColor: AppColors.primary,
          onCopy: () => ClipboardService.copyToClipboard(_cascadeSummary, context),
          content: Text(
            TextFormatter.formatClinicalText(_cascadeSummary),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      );
    }
    
    // Anamnese
    if (anamnesisText.isNotEmpty &&
        anamnesisText != 'Inicie a conversa para gerar análise automática...' &&
        anamnesisText != 'IA conectada. Analisando atendimento...') {
      sections.add(
        _buildMinimalCard(
          title: 'Anamnese',
          icon: Icons.medical_information,
          accentColor: AppColors.accent,
          onCopy: () => ClipboardService.copyToClipboard(anamnesisText, context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: anamnesisSections.entries
                .where((e) => e.value.isNotEmpty)
                .map((entry) {
              final key = entry.key;
              final content = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          sectionIcons[key] ?? Icons.info,
                          size: 16,
                          color: sectionColors[
                              anamnesisSections.keys.toList().indexOf(key) %
                                  sectionColors.length],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sectionLabels[key] ?? key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    
    // Prescrição do Médico
    if ((_cascadePrescription != null && _cascadePrescription!.isNotEmpty) ||
        (_prescription != null && _prescription!.isNotEmpty)) {
      sections.add(
        _buildMinimalCard(
          title: 'Prescrição do Médico',
          icon: Icons.medication,
          accentColor: AppColors.success,
          onCopy: () => ClipboardService.copyToClipboard(
            _cascadePrescription ?? _prescription ?? '',
            context,
          ),
          content: Text(
            TextFormatter.formatPrescription(
              _cascadePrescription ?? _prescription,
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      );
    }
    
    // Medicamentos Sugeridos pela IA
    if (_cascadeSuggestedMedications != null && _cascadeSuggestedMedications!.isNotEmpty) {
      sections.add(
        _buildMinimalCard(
          title: 'Medicamentos Sugeridos pela IA',
          icon: Icons.auto_awesome,
          accentColor: AppColors.warning,
          onCopy: () => ClipboardService.copyToClipboard(
            _cascadeSuggestedMedications ?? '',
            context,
          ),
          content: Text(
            TextFormatter.formatSuggestedMedications(
              _cascadeSuggestedMedications,
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      );
    }
    
    // Perguntas Sugeridas
    if (_cascadeSuggestedQuestions.isNotEmpty || _suggestedQuestions.isNotEmpty) {
      sections.add(
        _buildMinimalCard(
          title: 'Perguntas Sugeridas',
          icon: Icons.help_outline,
          accentColor: AppColors.info,
          onCopy: () => ClipboardService.copyToClipboard(
            (_cascadeSuggestedQuestions.isNotEmpty
                    ? _cascadeSuggestedQuestions
                    : _suggestedQuestions)
                .join('\n• '),
            context,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (_cascadeSuggestedQuestions.isNotEmpty
                    ? _cascadeSuggestedQuestions
                    : _suggestedQuestions)
                .map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      );
    }
    
    // Notas do Médico
    sections.add(
      _buildMinimalCard(
        title: 'Notas do Médico',
        icon: Icons.note,
        accentColor: AppColors.warning,
        onCopy: _doctorNotes.isNotEmpty
            ? () => ClipboardService.copyToClipboard(_doctorNotes, context)
            : null,
        content: TextField(
          controller: _notesController,
          maxLines: 8,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: 'Digite suas notas sobre o atendimento...',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceElevated,
          ),
          onChanged: (value) => _saveDoctorNotes(),
        ),
      ),
    );
    
    // Chat com IA
    sections.add(
      _buildMinimalCard(
        title: 'Chat com IA',
        icon: Icons.chat_bubble_outline,
        accentColor: AppColors.primary,
        onCopy: null,
        content: Column(
          children: [
            // Área de mensagens
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Faça perguntas sobre o atendimento...',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = _chatMessages[index];
                        final isUser = message['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                Icon(Icons.smart_toy, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message['content'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            // Campo de input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSendingChatMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: AppColors.primary,
                  onPressed: _isSendingChatMessage ? null : _sendChatMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    
    // Se for 1 coluna (mobile), retornar Column
    if (crossAxisCount == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          transcriptCard,
          ...sections,
          const SizedBox(height: 120),
        ],
      );
    }
    
    // Se for 2 colunas (desktop/tablet), retornar Column com transcrição e GridView
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Transcrição sempre ocupa largura total
        transcriptCard,
        // Grid com as demais seções
        if (crossAxisCount == 1)
          ...sections
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) => sections[index],
          ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildMinimalCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget content,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onCopy,
                    tooltip: 'Copiar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
            // Header minimalista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/clinical');
                      }
                    },
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atendimento Clínico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_patientName != null || _patientId != null)
                          Text(
                            _patientName ?? 'Paciente selecionado',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (!_isRecording && (_patientId == null && _patientName == null))
                    IconButton(
                      icon: const Icon(Icons.person_add, color: AppColors.primary),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => PatientSelectorWidget(
                            onPatientSelected: (patientId, anonymousName) {
                              setState(() {
                                _patientId = patientId;
                                _patientName = anonymousName;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                      tooltip: 'Selecionar paciente',
                    ),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Gravando',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_all, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: _copyAll,
                    tooltip: 'Copiar tudo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: _downloadPDF,
                    tooltip: 'Baixar PDF',
                  ),
                ],
              ),
            ),
            // Conteúdo scrollável com layout responsivo
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Detectar se é desktop/tablet (largura >= 768px)
                  final isDesktopOrTablet = constraints.maxWidth >= 768;
                  final crossAxisCount = isDesktopOrTablet ? 2 : 1;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildContentGrid(crossAxisCount, constraints.maxWidth),
                  );
                },
              ),
            ),
              ],
            ),
          ),
          // Botões flutuantes na parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.9),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                elevation: 1000,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Botão de gravação centralizado
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isRecording
                                ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                                : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? AppColors.error : AppColors.primary).withOpacity(0.6),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    // Botão de finalizar consulta (ao lado direito)
                    if (!_isRecording && _consultationId != null && !_isConsultationFinished)
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: GestureDetector(
                          onTap: _isProcessing ? null : _finishConsultation,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
