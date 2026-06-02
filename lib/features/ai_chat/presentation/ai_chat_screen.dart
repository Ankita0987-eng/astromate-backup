import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    
    final message = _messageController.text;
    _messageController.clear();
    
    // TODO: Send message to AI service
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmic Assistant'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildAssistantMessage(
                  'Hello! I\'m your Cosmic Assistant. Ask me anything about astrology, your birth chart, compatibility, or cosmic insights! ✨',
                  context,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildUserMessage('What does my birth chart say?', context, isDark),
                const SizedBox(height: 12),
                _buildAssistantMessage(
                  'I can see you\'re a Taurus Sun with a Leo Moon. This combination gives you grounded ambition with a dramatic flair. Your Leo Moon makes you crave recognition and creativity.',
                  context,
                  isDark,
                ),
              ],
            ),
          ),
          // Message input
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'send',
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text, BuildContext context, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(String text, BuildContext context, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
