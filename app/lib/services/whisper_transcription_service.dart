import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class WhisperTranscriptionService {
  StreamController<String>? _transcriptController;
  js.JsObject? _mediaStream; // Usar JsObject em vez de html.MediaStream
  js.JsObject? _mediaRecorder;
  Timer? _chunkTimer;
  String _fullTranscript = '';
  String? _consultationId;
  final ApiService _apiService = ApiService();
  
  // Instância Dio separada para requisições à OpenAI
  final Dio _openaiDio = Dio();
  
  // API Key da OpenAI (obtida do backend)
  String? _openaiApiKey;
  
  // Buffer para acumular chunks de áudio (usando JavaScript Blob)
  // Usar dynamic porque Blob não pode ser convertido diretamente para JsObject
  final List<dynamic> _audioChunks = [];
  
  bool _isRecording = false;
  
  // Detecção de voz (VAD - Voice Activity Detection)
  js.JsObject? _audioContext;
  js.JsObject? _analyserNode;
  js.JsObject? _sourceNode;
  Timer? _vadTimer;
  bool _isVoiceDetected = false;
  DateTime? _lastVoiceTime;
  DateTime? _silenceStartTime;
  int _vadLogCounter = 0;
  
  // Configurações de VAD
  static const double _voiceThreshold = 5.0; // Threshold de volume para detectar voz (0-100) - reduzido de 30 para 5
  static const Duration _silenceDuration = Duration(seconds: 2); // Tempo de silêncio antes de parar
  static const Duration _vadCheckInterval = Duration(milliseconds: 100); // Intervalo para verificar VAD

  Stream<String>? get transcriptStream => _transcriptController?.stream;
  String get currentTranscript => _fullTranscript;
  bool get isRecording => _isRecording;
  String? get consultationId => _consultationId;

  Future<void> startRecording({String? consultationId}) async {
    if (_isRecording) return;

    if (!kIsWeb) {
      throw Exception('Transcrição Whisper disponível apenas na web');
    }

    try {
      // Se consultationId foi fornecido, usar ele
      if (consultationId != null) {
        _consultationId = consultationId;
        print('[WhisperService] Usando consultationId fornecido: $consultationId');
      }

      // Solicitar acesso ao microfone via JavaScript
      final navigator = js.context['navigator'] as js.JsObject;
      final mediaDevices = navigator['mediaDevices'] as js.JsObject;
      final getUserMedia = mediaDevices['getUserMedia'] as js.JsObject;
      
      final audioConstraints = js.JsObject.jsify({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        }
      });

      final streamPromise = getUserMedia.callMethod('call', [mediaDevices, audioConstraints]);
      final stream = await _promiseToFuture(streamPromise);
      
      // Log para debug
      print('[WhisperService] Stream recebido - tipo: ${stream.runtimeType}');
      
      // Converter para JsObject se necessário
      if (stream is js.JsObject) {
        _mediaStream = stream;
      } else {
        _mediaStream = js.JsObject(stream);
      }
      
      _audioChunks.clear();
      _fullTranscript = '';
      _isRecording = true;
      _isVoiceDetected = false;
      _lastVoiceTime = null;
      _silenceStartTime = null;
      
      // Inicializar detecção de voz (VAD)
      await _initializeVAD();

      // Criar MediaRecorder via JavaScript - usar JsObject diretamente
      final MediaRecorder = js.context['MediaRecorder'];
      _mediaRecorder = js.JsObject(MediaRecorder, [_mediaStream]);

      // Configurar handlers
      _setupMediaRecorderHandlers();

      // NÃO iniciar gravação imediatamente - aguardar detecção de voz
      // A gravação será iniciada quando a voz for detectada pelo VAD
      // O VAD também controla quando parar a gravação (silêncio prolongado)

      // Criar stream controller
      _transcriptController = StreamController<String>.broadcast();

      // Obter API Key da OpenAI do backend
      await _getOpenAIApiKey();

      // NÃO criar consulta aqui - o AudioService já cria a consulta
      // O consultationId será passado como parâmetro
      if (_consultationId == null) {
        print('[WhisperService] AVISO: Nenhum consultationId fornecido, criando consulta fallback');
        await _startConsultation();
      } else {
        print('[WhisperService] Usando consultationId fornecido: $_consultationId');
      }

      print('[WhisperService] Sistema de gravação ativado - aguardando detecção de voz');
    } catch (e) {
      _isRecording = false;
      throw Exception('Erro ao iniciar gravação: $e');
    }
  }

  Future<dynamic> _promiseToFuture(js.JsObject promise) async {
    final completer = Completer<dynamic>();
    promise.callMethod('then', [
      js.allowInterop((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }),
      js.allowInterop((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      })
    ]);
    return completer.future;
  }

  void _processJavaScriptChunks() {
    try {
      final chunks = js.context['_whisperAudioChunks'] as js.JsObject?;
      if (chunks != null) {
        final length = chunks['length'] as int? ?? 0;
        for (int i = 0; i < length; i++) {
          // O chunk é um Blob do JavaScript, armazenar como dynamic
          final chunk = chunks[i];
          if (chunk != null) {
            _audioChunks.add(chunk);
          }
        }
        // Limpar chunks processados do array JavaScript
        if (length > 0) {
          chunks.callMethod('splice', [0, length]);
        }
      }
    } catch (e) {
      print('[WhisperService] Erro ao processar chunks do JavaScript: $e');
    }
  }

  Future<void> _startConsultation() async {
    try {
      final response = await _apiService.post(ApiConstants.startRecording);
      _consultationId = response.data['consultationId'] as String?;
      print('[WhisperService] Consulta iniciada: $_consultationId');
      
    } catch (e) {
      print('[WhisperService] Erro ao iniciar consulta: $e');
      // Continuar mesmo se falhar, mas sem consultationId
    }
  }
  

  Future<void> _sendAudioChunk() async {
    // Enviar chunk diretamente para OpenAI
    await _sendAudioChunkToOpenAI();
  }
  
  /// Obtém a API Key da OpenAI do backend
  Future<void> _getOpenAIApiKey() async {
    if (_openaiApiKey != null && _openaiApiKey!.isNotEmpty) {
      return; // Já temos a API key
    }
    
    try {
      final response = await _apiService.get('/clinical/openai-key');
      _openaiApiKey = response.data['apiKey'] as String?;
      if (_openaiApiKey == null || _openaiApiKey!.isEmpty) {
        throw Exception('API Key não retornada pelo backend');
      }
      print('[WhisperService] API Key obtida do backend');
    } catch (e) {
      print('[WhisperService] Erro ao obter API Key: $e');
      throw Exception('Não foi possível obter a API Key da OpenAI: $e');
    }
  }
  
  /// Inicializa a detecção de voz (VAD) usando Web Audio API
  Future<void> _initializeVAD() async {
    try {
      // Criar AudioContext
      final AudioContext = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (AudioContext == null) {
        print('[WhisperService] AudioContext não disponível, VAD desabilitado');
        // Se VAD não estiver disponível, iniciar gravação imediatamente
        if (_mediaRecorder != null) {
          _mediaRecorder!.callMethod('start', []);
        }
        return;
      }
      
      _audioContext = js.JsObject(AudioContext, []);
      
      // Criar AnalyserNode
      _analyserNode = _audioContext!.callMethod('createAnalyser', []);
      _analyserNode!['fftSize'] = 2048;
      _analyserNode!['smoothingTimeConstant'] = 0.8;
      
      // Conectar o stream de áudio ao AnalyserNode
      _sourceNode = _audioContext!.callMethod('createMediaStreamSource', [_mediaStream]);
      _sourceNode!.callMethod('connect', [_analyserNode]);
      
      // Iniciar loop de detecção de voz
      _startVADLoop();
      
      print('[WhisperService] VAD inicializado');
    } catch (e) {
      print('[WhisperService] Erro ao inicializar VAD: $e');
      // Se falhar, iniciar gravação imediatamente
      if (_mediaRecorder != null) {
        _mediaRecorder!.callMethod('start', []);
      }
    }
  }
  
  /// Inicia o loop de detecção de voz
  void _startVADLoop() {
    _vadTimer?.cancel();
    _vadTimer = Timer.periodic(_vadCheckInterval, (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      _checkVoiceActivity();
    });
  }
  
  /// Verifica atividade de voz e controla a gravação
  void _checkVoiceActivity() {
    try {
      if (_analyserNode == null) return;
      
      // Passar o analyser via variável global temporária para evitar conversão de tipos
      js.context['_whisperTempAnalyser'] = _analyserNode;
      final averageLevelResult = js.context.callMethod('eval', [
        '''
        (function() {
          if (!window._whisperVADDataArray) {
            window._whisperVADDataArray = new Uint8Array(2048);
          }
          var analyser = window._whisperTempAnalyser;
          if (!analyser) return 0;
          analyser.getByteFrequencyData(window._whisperVADDataArray);
          var sum = 0;
          for (var i = 0; i < window._whisperVADDataArray.length; i++) {
            sum += window._whisperVADDataArray[i];
          }
          return window._whisperVADDataArray.length > 0 ? (sum / window._whisperVADDataArray.length) : 0;
        })()
        '''
      ]);
      
      // O resultado é um número JavaScript, converter para double
      final averageLevel = (averageLevelResult as num?)?.toDouble() ?? 0.0;
      
      final now = DateTime.now();
      
      // Log periódico do nível de áudio (a cada ~5 segundos)
      _vadLogCounter++;
      if (_vadLogCounter % 50 == 0) {
        print('[WhisperService] Nível de áudio: $averageLevel (threshold: $_voiceThreshold, voz detectada: $_isVoiceDetected)');
      }
      
      // Log quando voz é detectada
      if (averageLevel > _voiceThreshold && !_isVoiceDetected) {
        print('[WhisperService] Voz detectada! Nível: $averageLevel > $_voiceThreshold');
      }
      
      // Detectar voz
      if (averageLevel > _voiceThreshold) {
        if (!_isVoiceDetected) {
          // Voz detectada - iniciar gravação
          _isVoiceDetected = true;
          _lastVoiceTime = now;
          _silenceStartTime = null;
          
          if (_mediaRecorder != null && _mediaStream != null) {
            try {
              final state = _mediaRecorder!['state'] as String?;
              if (state != 'recording') {
                // Se o MediaRecorder foi parado, criar um novo
                if (state == 'inactive') {
                  final MediaRecorder = js.context['MediaRecorder'];
                  _mediaRecorder = js.JsObject(MediaRecorder, [_mediaStream]);
                  _setupMediaRecorderHandlers();
                }
                _mediaRecorder!.callMethod('start', []);
                print('[WhisperService] Gravação iniciada (voz detectada)');
              }
            } catch (e) {
              print('[WhisperService] Erro ao iniciar gravação: $e');
            }
          }
        } else {
          // Voz continua - atualizar último tempo
          _lastVoiceTime = now;
          _silenceStartTime = null;
        }
      } else {
        // Silêncio detectado
        if (_isVoiceDetected) {
          if (_silenceStartTime == null) {
            _silenceStartTime = now;
          } else {
            // Verificar se o silêncio durou tempo suficiente
            final silenceDuration = now.difference(_silenceStartTime!);
            if (silenceDuration >= _silenceDuration) {
              // Silêncio prolongado - parar gravação
              _isVoiceDetected = false;
              _silenceStartTime = null;
              
              if (_mediaRecorder != null) {
                try {
                  final state = _mediaRecorder!['state'] as String?;
                  if (state == 'recording') {
                    _mediaRecorder!.callMethod('stop', []);
                    print('[WhisperService] Gravação pausada (silêncio detectado)');
                    
                    // Processar e enviar o chunk final
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _processJavaScriptChunks();
                      _sendAudioChunk();
                    });
                  }
                } catch (e) {
                  print('[WhisperService] Erro ao parar gravação: $e');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('[WhisperService] Erro ao verificar atividade de voz: $e');
    }
  }
  
  /// Configura os handlers do MediaRecorder
  void _setupMediaRecorderHandlers() {
    // Configurar handler para quando dados estiverem disponíveis
    // Criar função JavaScript que armazena chunks em array global
    js.context.callMethod('eval', [
      'window._whisperAudioChunks = []; window._whisperOnDataAvailable = function(event) { if (event && event.data) { window._whisperAudioChunks.push(event.data); } };'
    ]);
    
    final onDataAvailable = js.context['_whisperOnDataAvailable'] as js.JsObject;
    _mediaRecorder!['ondataavailable'] = onDataAvailable;

    // Configurar handler para erros
    _mediaRecorder!['onerror'] = js.allowInterop((dynamic event) {
      try {
        print('[WhisperService] Erro no MediaRecorder: $event');
      } catch (e) {
        print('[WhisperService] Erro ao processar erro: $e');
      }
    });
  }
  
  /// Converte Blob JavaScript para Uint8List do Dart
  Future<Uint8List> _blobToUint8List(dynamic blob) async {
    try {
      // Usar JavaScript para ler o Blob como ArrayBuffer
      final readBlobAsArrayBuffer = js.context.callMethod('eval', [
        '''
        (function(blob) {
          return new Promise(function(resolve, reject) {
            var reader = new FileReader();
            reader.onload = function(e) { 
              try {
                var arrayBuffer = e.target.result;
                var uint8Array = new Uint8Array(arrayBuffer);
                var array = Array.from(uint8Array);
                resolve(array);
              } catch(err) {
                reject(err);
              }
            };
            reader.onerror = function(e) { reject(new Error('Erro ao ler blob')); };
            reader.readAsArrayBuffer(blob);
          });
        })
        '''
      ]) as js.JsObject;
      
      // Chamar a função e aguardar o resultado
      final promise = readBlobAsArrayBuffer.callMethod('call', [js.context, blob]);
      final result = await _promiseToFuture(promise);
      
      // Converter resultado JavaScript para Uint8List
      if (result is js.JsObject) {
        final length = result['length'] as int? ?? 0;
        if (length == 0) {
          return Uint8List(0);
        }
        final list = <int>[];
        for (int i = 0; i < length; i++) {
          final value = result[i];
          if (value != null) {
            list.add(value as int);
          }
        }
        return Uint8List.fromList(list);
      } else if (result is List) {
        return Uint8List.fromList(result.cast<int>());
      }
      
      print('[WhisperService] Tipo de resultado inesperado: ${result.runtimeType}');
      return Uint8List(0);
    } catch (e) {
      print('[WhisperService] Erro ao converter Blob para Uint8List: $e');
      return Uint8List(0);
    }
  }
  
  /// Envia chunk de áudio diretamente para a API da OpenAI
  Future<void> _sendAudioChunkToOpenAI() async {
    if (!_isRecording || _audioChunks.isEmpty) return;
    
    // Garantir que temos a API key
    if (_openaiApiKey == null || _openaiApiKey!.isEmpty) {
      try {
        await _getOpenAIApiKey();
      } catch (e) {
        print('[WhisperService] Não foi possível obter API Key, pulando chunk: $e');
        return;
      }
    }

    try {
      // Pegar o último chunk (o mais recente, que deve ser um WebM válido completo de stop())
      final chunk = _audioChunks.removeLast();
      
      // Limpar todos os chunks antigos
      _audioChunks.clear();
      
      // Converter Blob para Uint8List
      final uint8List = await _blobToUint8List(chunk);
      
      if (uint8List.isEmpty) {
        print('[WhisperService] Chunk vazio, pulando');
        return;
      }
      
      // Verificar se o chunk é grande o suficiente (mínimo ~10KB para ser um WebM válido)
      if (uint8List.length < 10000) {
        print('[WhisperService] Chunk muito pequeno (${uint8List.length} bytes), pulando');
        return;
      }

      // Criar FormData para enviar para OpenAI
      // Especificar Content-Type explicitamente para WebM
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          uint8List,
          filename: 'audio.webm',
        ),
        'model': 'whisper-1',
        'language': 'pt',
        'response_format': 'text',
      });

      print('[WhisperService] Enviando ${uint8List.length} bytes para OpenAI (formato: webm)');

      // Enviar diretamente para API da OpenAI
      final response = await _openaiDio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openaiApiKey',
          },
          validateStatus: (status) => status! < 500, // Não lançar exceção para 400, apenas logar
        ),
      );

      // Verificar status da resposta
      if (response.statusCode != 200) {
        String errorMessage;
        if (response.data is Map) {
          final errorMap = (response.data as Map)['error'];
          if (errorMap is Map && errorMap['message'] != null) {
            errorMessage = errorMap['message'].toString();
          } else {
            errorMessage = response.data.toString();
          }
        } else {
          errorMessage = response.data.toString();
        }
        print('[WhisperService] Erro da API OpenAI: ${response.statusCode} - $errorMessage');
        return;
      }

      // A resposta é uma string quando response_format é 'text'
      final transcribedText = response.data as String? ?? response.data['text'] as String? ?? '';

      if (transcribedText.isNotEmpty) {
        // Atualizar transcrição completa
        _fullTranscript = _fullTranscript.isEmpty
            ? transcribedText
            : '$_fullTranscript $transcribedText';
        
        // Emitir transcrição completa acumulada
        _transcriptController?.add(_fullTranscript);
        print('[WhisperService] Transcrição recebida: ${transcribedText.substring(0, transcribedText.length > 50 ? 50 : transcribedText.length)}...');
      } else {
        print('[WhisperService] Resposta vazia da API OpenAI');
      }
    } catch (e) {
      // Capturar e logar detalhes do erro
      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final errorData = e.response!.data;
          String errorMessage;
          if (errorData is Map) {
            final errorMap = errorData['error'];
            if (errorMap is Map && errorMap['message'] != null) {
              errorMessage = errorMap['message'].toString();
            } else {
              errorMessage = errorData.toString();
            }
          } else {
            errorMessage = errorData.toString();
          }
          print('[WhisperService] Erro ao enviar chunk para OpenAI: $statusCode - $errorMessage');
        } else {
          print('[WhisperService] Erro de conexão ao enviar chunk para OpenAI: ${e.message}');
        }
      } else {
        print('[WhisperService] Erro ao enviar chunk para OpenAI: $e');
      }
      // Continuar gravação mesmo se um chunk falhar
    }
  }
  

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    
    // Parar VAD
    _vadTimer?.cancel();
    _vadTimer = null;
    
    // Limpar recursos de áudio
    try {
      if (_sourceNode != null) {
        _sourceNode!.callMethod('disconnect', []);
        _sourceNode = null;
      }
      if (_audioContext != null) {
        _audioContext!.callMethod('close', []);
        _audioContext = null;
      }
      _analyserNode = null;
    } catch (e) {
      print('[WhisperService] Erro ao limpar recursos de VAD: $e');
    }
    
    _chunkTimer?.cancel();
    _chunkTimer = null;

    // Parar MediaRecorder
    if (_mediaRecorder != null) {
      try {
        final state = _mediaRecorder!['state'] as String?;
        if (state == 'recording') {
          _mediaRecorder!.callMethod('stop', []);
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        print('[WhisperService] Erro ao parar MediaRecorder: $e');
      }
      _mediaRecorder = null;
    }

    // Parar tracks do stream
    if (_mediaStream != null) {
      try {
        // Chamar getAudioTracks() no stream
        final getAudioTracks = _mediaStream!['getAudioTracks'] as js.JsObject?;
        if (getAudioTracks != null) {
          final tracksList = getAudioTracks.callMethod('call', [_mediaStream]) as js.JsObject?;
          if (tracksList != null) {
            // Iterar sobre os tracks e parar cada um
            final length = tracksList['length'] as int? ?? 0;
            for (int i = 0; i < length; i++) {
              final track = tracksList[i] as js.JsObject?;
              track?.callMethod('stop');
            }
          }
        }
      } catch (e) {
        print('[WhisperService] Erro ao parar tracks: $e');
      }
      _mediaStream = null;
    }

    // Processar chunks restantes do JavaScript
    _processJavaScriptChunks();
    
    // Enviar chunks acumulados restantes se houver
    if (_audioChunks.isNotEmpty) {
      await _sendAudioChunk();
    }

    print('[WhisperService] Gravação parada');
  }

  void dispose() {
    stopRecording();
    _transcriptController?.close();
    _transcriptController = null;
    _fullTranscript = '';
    _consultationId = null;
  }
}

