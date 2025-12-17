import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'websocket_service.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final WebSocketService _wsService = WebSocketService();
  bool _isRecording = false;
  StreamController<Map<String, dynamic>>? _transcriptController;
  Timer? _chunkTimer;
  String? _consultationId;

  bool get isRecording => _isRecording;

  Stream<Map<String, dynamic>>? get transcriptStream => _transcriptController?.stream;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Permissão de microfone negada');
    }

    // Obter token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    // Conectar WebSocket
    await _wsService.connect(token);

    // Escutar mensagens do WebSocket
    _transcriptController = StreamController<Map<String, dynamic>>.broadcast();
    _wsService.messageStream?.listen((message) {
      if (message['type'] == 'transcript') {
        _transcriptController?.add(message);
      } else if (message['type'] == 'started') {
        _consultationId = message['consultationId'];
      }
    });

    // Iniciar gravação
    // Para web, o path pode ser null ou vazio
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
      ),
      path: '', // Path vazio para web/streaming
    );

    // Iniciar sessão no backend
    _wsService.startRecording();

    _isRecording = true;

    // Enviar chunks periodicamente usando stream de áudio
    // Nota: O package record pode não ter stream direto, então usamos uma abordagem alternativa
    // Enviando transcrição de texto quando disponível (o cliente pode fazer transcrição básica)
    _chunkTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      try {
        // Por enquanto, enviamos um placeholder
        // Em produção, isso seria substituído por chunks de áudio reais
        // ou transcrição feita no cliente usando speech_to_text
      } catch (e) {
        print('Error in chunk timer: $e');
      }
    });
  }

  String _encodeAudioChunk(Uint8List data) {
    // Converter PCM16 para base64
    return base64Encode(data);
  }

  // Método para enviar transcrição de texto (quando disponível no cliente)
  void sendTextChunk(String text) {
    if (_isRecording && _wsService.isConnected) {
      _wsService.sendTextChunk(text);
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _chunkTimer?.cancel();
    
    await _recorder.stop();
    _wsService.stopRecording();
    await _wsService.disconnect();
    
    await _transcriptController?.close();
    _transcriptController = null;
    _consultationId = null;
  }

  String? get consultationId => _consultationId;

  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
  }
}

