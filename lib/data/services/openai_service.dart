import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';
import '../models/chat_message.dart';

/// AI chat service backed by Groq (free, OpenAI-compatible SSE streaming).
///
/// Falls back to a deterministic mock stream when no Groq key is configured
/// or when the API returns a non-200 response.
class OpenAiService {
  OpenAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.1-70b-versatile';

  static const _relationshipKeywords = [
    'ex', 'partner', 'love', 'compatible', 'relationship', 'date', 'marry',
    'marriage', 'crush', 'boyfriend', 'girlfriend', 'soulmate', 'twin flame',
  ];

  /// Builds the system prompt with user context and relationship-aware
  /// astrological guidance when relevant keywords are detected.
  String _buildSystemPrompt(String userMessage, UserContext? context) {
    const base =
        'You are Cosmic Match AI, a warm expert astrologer. '
        'Give insightful, empathetic relationship and chart advice. '
        'Use markdown sparingly. Keep responses concise but meaningful.';

    final userCtx = context != null
        ? ' User: ${context.name}, sign: ${context.zodiacSign ?? "unknown"}, '
          'status: ${context.relationshipStatus ?? "unknown"}.'
        : '';

    final lower = userMessage.toLowerCase();
    final isRelationship =
        _relationshipKeywords.any((kw) => lower.contains(kw));

    final astroCtx = isRelationship && context?.zodiacSign != null
        ? ' When discussing relationships, reference the user\'s '
          '${context!.zodiacSign} traits: emotional depth, communication '
          'style, and compatibility patterns.'
        : '';

    return '$base$userCtx$astroCtx';
  }

  Stream<String> streamChat({
    required List<ChatMessage> history,
    required String userMessage,
    UserContext? context,
  }) async* {
    // Use Groq when a key is configured; otherwise fall straight to mock.
    if (!EnvConfig.hasGroq) {
      yield* _mockStream(userMessage, context);
      return;
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(userMessage, context),
      },
      ...history.map((m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final request = http.Request('POST', Uri.parse(_groqEndpoint));
      request.headers.addAll({
        'Authorization': 'Bearer ${EnvConfig.groqApiKey}',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': _groqModel,
        'messages': messages,
        'stream': true,
        'temperature': 0.8,
        'max_tokens': 800,
      });

      final response = await _client.send(request);

      if (response.statusCode != 200) {
        debugPrint(
          'OpenAiService(Groq): non-200 response (${response.statusCode}) — falling back to mock',
        );
        yield* _mockStream(userMessage, context);
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          // Post-200 parse errors propagate to the caller — no catch here.
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'];
          if (delta is String && delta.isNotEmpty) yield delta;
        }
      }
    } catch (e) {
      debugPrint('OpenAiService(Groq): error $e — falling back to mock');
      yield* _mockStream(userMessage, context);
    }
  }

  Stream<String> _mockStream(String userMessage, UserContext? context) async* {
    final lower = userMessage.toLowerCase();
    String response;
    if (lower.contains('ex')) {
      response =
          'The stars suggest closure and growth rather than reunion cycles. '
          'Your ${context?.zodiacSign ?? "chart"} indicates healing through self-love first. '
          'If they return, it will be when you no longer need them to complete you. ✨';
    } else if (lower.contains('compatible')) {
      response =
          'Compatibility is more than sun signs — look at emotional rhythm and communication. '
          'Trust your intuition when you are around them; your body often knows before your mind.';
    } else if (lower.contains('date')) {
      response =
          'Venus favors bold honesty this week. If this person energizes you and respects boundaries, '
          'the cosmos support exploration. Move slowly and observe consistency over words.';
    } else if (lower.contains('chart')) {
      response =
          'Your birth chart is a map of potentials: sun (identity), moon (emotions), rising (first impression). '
          'Together they explain why you love, fight, and dream the way you do. Ask me about a specific placement!';
    } else {
      response =
          'The universe whispers: trust divine timing. Your cosmic path unfolds through aligned choices. '
          'What specific area — love, career, or healing — calls to you today? 🔮';
    }
    for (var i = 0; i < response.length; i += 4) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      yield response.substring(i, (i + 4).clamp(0, response.length));
    }
  }
}

class UserContext {
  const UserContext({
    required this.name,
    this.zodiacSign,
    this.relationshipStatus,
  });

  final String name;
  final String? zodiacSign;
  final String? relationshipStatus;
}
