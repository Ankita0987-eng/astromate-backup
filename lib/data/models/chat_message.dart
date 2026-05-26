import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'role': role.name,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      role: data['role'] == 'assistant'
          ? MessageRole.assistant
          : MessageRole.user,
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, role, content];
}

class AiChatSession extends Equatable {
  const AiChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, updatedAt];
}
