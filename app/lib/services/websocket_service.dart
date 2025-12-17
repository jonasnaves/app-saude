import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  String? _token;

  bool get isConnected => _isConnected;

  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  Future<void> connect(String token) async {
    if (_isConnected) return;

    _token = token;
    _messageController = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final uri = Uri.parse(ApiConstants.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      // Autenticar
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'token': token,
      }));

      // Escutar mensagens
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _messageController?.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _messageController?.add({'type': 'error', 'message': error.toString()});
        },
        onDone: () {
          _isConnected = false;
          _messageController?.add({'type': 'disconnected'});
        },
      );

      // Aguardar confirmação de autenticação
      await _channel!.stream.firstWhere((message) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        if (data['type'] == 'auth' && data['success'] == true) {
          _isConnected = true;
          return true;
        }
        return false;
      }).timeout(const Duration(seconds: 5));

      print('WebSocket connected');
    } catch (e) {
      print('Error connecting WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void send(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }
    _channel!.sink.add(jsonEncode(message));
  }

  void startRecording() {
    send({'type': 'start'});
  }

  void sendAudioChunk(String audioBase64) {
    send({
      'type': 'chunk',
      'audioData': audioBase64,
    });
  }

  void sendTextChunk(String text) {
    send({
      'type': 'chunk',
      'textChunk': text,
    });
  }

  void stopRecording() {
    send({'type': 'stop'});
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _messageController?.close();
    _channel = null;
    _messageController = null;
    _isConnected = false;
  }
}

