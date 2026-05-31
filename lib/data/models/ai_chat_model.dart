import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// AI Chat message with extended metadata.
class AIChatMessage extends Equatable {
  const AIChatMessage({
    required this.id,
    required this.userId,
    required this.userMessage,
    required this.aiResponse,
    required this.category, // birth_chart, compatibility, horoscope, relationships, spiritual
    required this.tokens,
    required this.timestamp,
    required this.context,
  });

  final String id;
  final String userId;
  final String userMessage;
  final String aiResponse;
  final String category;
  final int tokens;
  final DateTime timestamp;
  final Map<String, dynamic> context; // user data used for response

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userMessage': userMessage,
      'aiResponse': aiResponse,
      'category': category,
      'tokens': tokens,
      'timestamp': Timestamp.fromDate(timestamp),
      'context': context,
    };
  }

  factory AIChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIChatMessage(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userMessage: data['userMessage'] as String? ?? '',
      aiResponse: data['aiResponse'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      tokens: data['tokens'] as int? ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      context: Map<String, dynamic>.from(data['context'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, userId, timestamp];
}

/// AI usage statistics for a user.
class AIUsageStats extends Equatable {
  const AIUsageStats({
    required this.userId,
    required this.totalMessages,
    required this.totalTokens,
    required this.monthlyMessagesUsed,
    required this.monthlyTokensUsed,
    required this.topCategories,
    required this.lastUsed,
    required this.createdAt,
  });

  final String userId;
  final int totalMessages;
  final int totalTokens;
  final int monthlyMessagesUsed;
  final int monthlyTokensUsed;
  final Map<String, int> topCategories; // category -> count
  final DateTime lastUsed;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalMessages': totalMessages,
      'totalTokens': totalTokens,
      'monthlyMessagesUsed': monthlyMessagesUsed,
      'monthlyTokensUsed': monthlyTokensUsed,
      'topCategories': topCategories,
      'lastUsed': Timestamp.fromDate(lastUsed),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AIUsageStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIUsageStats(
      userId: doc.id,
      totalMessages: data['totalMessages'] as int? ?? 0,
      totalTokens: data['totalTokens'] as int? ?? 0,
      monthlyMessagesUsed: data['monthlyMessagesUsed'] as int? ?? 0,
      monthlyTokensUsed: data['monthlyTokensUsed'] as int? ?? 0,
      topCategories: Map<String, int>.from(data['topCategories'] as Map? ?? {}),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, totalMessages, monthlyMessagesUsed];
}
