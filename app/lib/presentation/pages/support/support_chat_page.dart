import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SupportChatPage extends StatefulWidget {
  final String mode;

  const SupportChatPage({super.key, required this.mode});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  String get _modeLabel {
    switch (widget.mode) {
      case 'medical':
        return 'IA Médica';
      case 'legal':
        return 'IA Jurídica';
      case 'marketing':
        return 'IA Marketing';
      default:
        return 'IA';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': message});
      _isLoading = true;
    });

    // TODO: Enviar mensagem para API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _messages.add({
        'role': 'bot',
        'text': 'Resposta da IA será implementada aqui',
      });
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: Text(_modeLabel),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.slateLight),
                        const SizedBox(height: 16),
                        Text(
                          'Inicie uma conversa com $_modeLabel',
                          style: const TextStyle(color: AppColors.slateLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.electricBlue : AppColors.slate800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate900.withOpacity(0.5),
              border: Border(
                top: BorderSide(color: AppColors.slate700),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      hintStyle: const TextStyle(color: AppColors.slateLight),
                      filled: true,
                      fillColor: AppColors.slate800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.electricBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

