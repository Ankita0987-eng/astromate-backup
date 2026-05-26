import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/services/openai_service.dart';
import '../../../providers/app_providers.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.chatId});

  final String? chatId;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  String? _sessionId;
  bool _streaming = false;
  String _streamingBuffer = '';

  static const _suggestions = [
    'Will my ex come back?',
    'Are we compatible?',
    'Should I date this person?',
    'What does my chart mean?',
  ];

  @override
  void initState() {
    super.initState();
    _sessionId = widget.chatId;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || _sessionId == null) return;
    final history =
        await ref.read(chatRepositoryProvider).getMessages(user.uid, _sessionId!);
    setState(() => _messages.addAll(history));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _streaming) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    if (profile != null) {
      final canSend =
          await ref.read(userRepositoryProvider).canSendAiMessage(profile);
      if (!canSend) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily AI limit reached. Go Premium!')),
          );
          context.push('/premium');
        }
        return;
      }
    }

    _sessionId ??= await ref.read(chatRepositoryProvider).createSession(
          user.uid,
          text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _streaming = true;
      _streamingBuffer = '';
    });
    _controller.clear();
    _scrollToBottom();

    await ref.read(chatRepositoryProvider).addMessage(
          uid: user.uid,
          chatId: _sessionId!,
          message: userMsg,
        );

    if (profile != null && !profile.isPremium) {
      await ref.read(userRepositoryProvider).incrementAiUsage(user.uid);
    }

    final assistantId = const Uuid().v4();
    final context_ = profile != null
        ? UserContext(
            name: profile.displayName,
            zodiacSign: profile.zodiacSign,
            relationshipStatus: profile.relationshipStatus,
          )
        : null;

    // Fix: pass only messages before the current user message as history.
    await for (final chunk in ref.read(openAiServiceProvider).streamChat(
          history: _messages
              .where((m) => m.id != userMsg.id && m.id != assistantId)
              .toList(),
          userMessage: text,
          context: context_,
        )) {
      setState(() => _streamingBuffer += chunk);
      _scrollToBottom();
    }

    final assistantMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: _streamingBuffer,
      createdAt: DateTime.now(),
    );

    await ref.read(chatRepositoryProvider).addMessage(
          uid: user.uid,
          chatId: _sessionId!,
          message: assistantMsg,
        );

    setState(() {
      _messages.add(assistantMsg);
      _streaming = false;
      _streamingBuffer = '';
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('AI Astrology'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Column(
          children: [
            if (_messages.isEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _suggestions
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(s),
                            onPressed: () => _send(s),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_streaming ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length && _streaming) {
                    return _Bubble(
                      isUser: false,
                      content: _streamingBuffer.isEmpty
                          ? '...'
                          : _streamingBuffer,
                      isTyping: _streamingBuffer.isEmpty,
                    );
                  }
                  final msg = _messages[i];
                  return _Bubble(
                    isUser: msg.role == MessageRole.user,
                    content: msg.content,
                  );
                },
              ),
            ),
            _InputBar(
              controller: _controller,
              enabled: !_streaming,
              onSend: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.isUser,
    required this.content,
    this.isTyping = false,
  });

  final bool isUser;
  final String content;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? AppColors.cosmicGradient
              : null,
          color: isUser ? null : AppColors.deepSpace.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(
            color: isUser ? Colors.transparent : AppColors.glassBorder,
          ),
        ),
        child: isUser
            ? Text(content, style: const TextStyle(color: Colors.white))
            : isTyping
                ? const _TypingDots()
                : MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final opacity = ((_c.value * 3 + i) % 3) == 0 ? 1.0 : 0.3;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: 'Ask the cosmos...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
