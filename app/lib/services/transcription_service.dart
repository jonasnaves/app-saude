import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class TranscriptionService {
  StreamController<String>? _transcriptController;
  js.JsObject? _recognition;
  String _currentTranscript = '';

  Stream<String>? get transcriptStream => _transcriptController?.stream;
  String get currentTranscript => _currentTranscript;

  // Helper para enviar logs via JavaScript
  void _logDebug(String location, String message, Map<String, dynamic> data) {
    if (kIsWeb) {
      try {
        final fetch = js.context.callMethod('eval', ['window.fetch']);
        final JSON = js.context['JSON'];
        if (fetch != null && JSON != null) {
          final logData = js.JsObject.jsify({
            'location': location,
            'message': message,
            'data': data,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'run1',
            'hypothesisId': 'A',
          });
          final fetchObj = js.JsObject(fetch);
          fetchObj.callMethod('call', [
            js.context['window'],
            'http://127.0.0.1:7242/ingest/129c2ad8-876a-4abe-bcba-10bbc1950fc3',
            js.JsObject.jsify({
              'method': 'POST',
              'headers': js.JsObject.jsify({'Content-Type': 'application/json'}),
              'body': JSON.callMethod('stringify', [logData]),
            })
          ]).callMethod('catch', [js.allowInterop((_) {})]);
        }
      } catch (e) {
        // Ignorar erros de logging
      }
    }
    print('[DEBUG] $location: $message - $data');
  }

  bool get isSupported {
    if (!kIsWeb) {
      _logDebug('transcription_service.dart:14', 'isSupported: não é web', {'kIsWeb': false});
      return false;
    }
    try {
      // Acessar diretamente via js.context usando eval para verificar propriedades
      final result = js.context.callMethod('eval', [
        'typeof window.SpeechRecognition !== "undefined" || typeof window.webkitSpeechRecognition !== "undefined"'
      ]);
      final hasSupport = result == true;
      
      _logDebug('transcription_service.dart:20', 'Verificando suporte Web Speech API', {
        'hasSupport': hasSupport,
        'result': result.toString(),
      });
      
      return hasSupport;
    } catch (e) {
      _logDebug('transcription_service.dart:24', 'Erro ao verificar suporte', {'error': e.toString()});
      return false;
    }
  }

  void start() {
    _logDebug('transcription_service.dart:33', 'Método start() chamado', {});
    if (!kIsWeb) {
      _logDebug('transcription_service.dart:34', 'kIsWeb é false - não é web', {'kIsWeb': false});
      throw Exception('Transcrição em tempo real disponível apenas na web');
    }
    _logDebug('transcription_service.dart:36', 'kIsWeb é true - verificando isSupported', {'kIsWeb': true});
    
    final supported = isSupported;
    _logDebug('transcription_service.dart:38', 'isSupported retornou', {'supported': supported});
    if (!supported) {
      // Usar eval para obter informações de diagnóstico
      final hasStandard = js.context.callMethod('eval', ['typeof window.SpeechRecognition !== "undefined"']) == true;
      final hasWebkit = js.context.callMethod('eval', ['typeof window.webkitSpeechRecognition !== "undefined"']) == true;
      final userAgent = js.context.callMethod('eval', ['navigator.userAgent'])?.toString() ?? 'desconhecido';
      final protocol = js.context.callMethod('eval', ['window.location.protocol'])?.toString() ?? 'desconhecido';
      final hostname = js.context.callMethod('eval', ['window.location.hostname'])?.toString() ?? 'desconhecido';
      final isHttps = protocol == 'https:' || (protocol == 'http:' && (hostname == 'localhost' || hostname == '127.0.0.1'));
      
      _logDebug('transcription_service.dart:43', 'Web Speech API não suportada - diagnóstico completo', {
        'hasStandard': hasStandard,
        'hasWebkit': hasWebkit,
        'protocol': protocol,
        'hostname': hostname,
        'isHttps': isHttps,
        'userAgent': userAgent,
      });
      
      String errorMsg = 'Web Speech API não suportada neste navegador.\n\n';
      errorMsg += 'Requisitos:\n';
      errorMsg += '- Use Chrome, Edge ou Safari (versões recentes)\n';
      errorMsg += '- Acesso via HTTPS ou localhost\n';
      errorMsg += '- Permissão de microfone concedida\n\n';
      errorMsg += 'Informações de diagnóstico:\n';
      errorMsg += '- Protocolo: $protocol\n';
      errorMsg += '- Hostname: $hostname\n';
      errorMsg += '- HTTPS/Localhost: ${isHttps ? "sim" : "não"}\n';
      errorMsg += '- User Agent: $userAgent\n';
      errorMsg += '- SpeechRecognition: ${hasStandard ? "sim" : "não"}\n';
      errorMsg += '- webkitSpeechRecognition: ${hasWebkit ? "sim" : "não"}';
      
      throw Exception(errorMsg);
    }

    _transcriptController = StreamController<String>.broadcast();
    _currentTranscript = '';

    try {
      // Obter SpeechRecognition via eval
      final SpeechRecognition = js.context.callMethod('eval', [
        'window.SpeechRecognition || window.webkitSpeechRecognition'
      ]);
      
      _logDebug('transcription_service.dart:75', 'Tentando obter SpeechRecognition', {
        'hasSpeechRecognition': SpeechRecognition != null,
      });
      
      if (SpeechRecognition == null) {
        _logDebug('transcription_service.dart:79', 'SpeechRecognition é null', {});
        throw Exception('SpeechRecognition não encontrado. Verifique se está usando Chrome, Edge ou Safari.');
      }
      
      // Tentar instanciar para verificar se funciona
      try {
        _recognition = js.JsObject(SpeechRecognition);
        _logDebug('transcription_service.dart:86', 'SpeechRecognition instanciado com sucesso', {});
      } catch (e) {
        _logDebug('transcription_service.dart:89', 'Erro ao instanciar SpeechRecognition', {'error': e.toString()});
        throw Exception('Não foi possível instanciar SpeechRecognition: $e. Verifique se está em HTTPS ou localhost.');
      }
      
      _recognition!['continuous'] = true;
      _recognition!['interimResults'] = true;
      _recognition!['lang'] = 'pt-BR';

      // Usar o wrapper JavaScript se disponível
      final wrapperExists = js.context.callMethod('eval', ['typeof window.SpeechRecognitionWrapper !== "undefined"']) == true;
      if (wrapperExists) {
        final wrapperClass = js.context.callMethod('eval', ['window.SpeechRecognitionWrapper']);
        final wrapper = js.JsObject(wrapperClass);
        wrapper.callMethod('setOnResult', [
          js.allowInterop((js.JsObject result) {
            final finalText = result['final'] as String? ?? '';
            final interimText = result['interim'] as String? ?? '';

            if (finalText.isNotEmpty) {
              _currentTranscript = finalText;
              _transcriptController?.add(_currentTranscript);
            } else if (interimText.isNotEmpty) {
              final fullText = _currentTranscript.isEmpty 
                  ? interimText 
                  : '$_currentTranscript $interimText';
              _transcriptController?.add(fullText);
            }
          })
        ]);
        wrapper.callMethod('start');
      } else {
        // Fallback para implementação direta
        _recognition!['onresult'] = js.allowInterop((js.JsObject event) {
          try {
            final results = event['results'];
            String interimTranscript = '';
            String finalTranscript = '';

            final resultsLength = results['length'] as int? ?? 0;
            for (int i = 0; i < resultsLength; i++) {
              final result = results[i];
              // result[0] é o primeiro SpeechRecognitionAlternative
              final transcript = result[0]['transcript'] as String? ?? '';
              final isFinal = result['isFinal'] as bool? ?? false;
              
              if (isFinal) {
                finalTranscript += transcript;
              } else {
                interimTranscript += transcript;
              }
            }

            if (finalTranscript.isNotEmpty) {
              _currentTranscript = finalTranscript;
              _transcriptController?.add(_currentTranscript);
            } else if (interimTranscript.isNotEmpty) {
              final fullText = _currentTranscript.isEmpty 
                  ? interimTranscript 
                  : '$_currentTranscript $interimTranscript';
              _transcriptController?.add(fullText);
            }
          } catch (e) {
            _transcriptController?.addError('Erro ao processar resultado: $e');
          }
        });

        _recognition!['onerror'] = js.allowInterop((js.JsObject event) {
          final error = event['error'];
          _transcriptController?.addError('Erro de transcrição: $error');
        });

        _recognition!['onstart'] = js.allowInterop((_) {
          print('Speech recognition iniciado com sucesso');
        });

        _recognition!['onend'] = js.allowInterop((_) {
          print('Speech recognition finalizado');
        });

        _recognition!.callMethod('start');
      }
    } catch (e) {
      final errorMsg = 'Erro ao iniciar transcrição: $e';
      print(errorMsg);
      _transcriptController?.addError(errorMsg);
      rethrow;
    }
  }

  void stop() {
    try {
      if (_recognition != null) {
        _recognition!.callMethod('stop');
        _recognition = null;
      }
    } catch (e) {
      // Ignorar erros ao parar
    }
    _currentTranscript = '';
  }

  void dispose() {
    stop();
    _transcriptController?.close();
    _transcriptController = null;
  }
}

