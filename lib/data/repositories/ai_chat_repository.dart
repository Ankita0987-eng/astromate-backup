import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_chat_model.dart';

/// Repository for managing AI chat interactions and usage stats.
class AIChatRepository {
  AIChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _aiChatCollection = 'ai_chat_messages';
  static const String _usageStatsCollection = 'ai_usage_stats';

  /// Save an AI chat message
  Future<AIChatMessage> saveMessage(
    String userMessage,
    String aiResponse,
    String category, {
    int tokens = 0,
    Map<String, dynamic>? context,
  }) async {
    try {
      final docRef = _firestore
          .collection(_aiChatCollection)
          .doc(_userId)
          .collection('messages')
          .doc();
      
      final message = AIChatMessage(
        id: docRef.id,
        userId: _userId,
        userMessage: userMessage,
        aiResponse: aiResponse,
        category: category,
        tokens: tokens,
        timestamp: DateTime.now(),
        context: context ?? {},
      );
      
      await docRef.set(message.toMap());
      
      // Update usage stats
      await _updateUsageStats(tokens, category);
      
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Get AI chat history for user
  Future<List<AIChatMessage>> getChatHistory({
    int limit = 50,
    String? categoryFilter,
  }) async {
    try {
      Query query = _firestore
          .collection(_aiChatCollection)
          .doc(_userId)
          .collection('messages');
      
      if (categoryFilter != null) {
        query = query.where('category', isEqualTo: categoryFilter);
      }
      
      final docs = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return docs.docs
          .map((doc) => AIChatMessage.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream AI chat messages (real-time)
  Stream<List<AIChatMessage>> watchChatHistory({String? categoryFilter}) {
    Query query = _firestore
        .collection(_aiChatCollection)
        .doc(_userId)
        .collection('messages');
    
    if (categoryFilter != null) {
      query = query.where('category', isEqualTo: categoryFilter);
    }
    
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatMessage.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }

  /// Get AI usage stats for user
  Future<AIUsageStats?> getUsageStats() async {
    try {
      final doc = await _firestore
          .collection(_usageStatsCollection)
          .doc(_userId)
          .get();
      
      if (!doc.exists) return null;
      return AIUsageStats.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream usage stats (real-time)
  Stream<AIUsageStats?> watchUsageStats() {
    return _firestore
        .collection(_usageStatsCollection)
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.exists ? AIUsageStats.fromFirestore(doc) : null);
  }

  /// Check if user has AI chat available
  Future<bool> canUseAIChat() async {
    try {
      // Check subscription status
      final subscription = await _getSubscription();
      if (subscription == null) return false;
      
      if (!subscription['isActive']) return false;
      
      // Check monthly limit
      final monthlyLimit = subscription['monthlyAIMessages'] as int? ?? 0;
      if (monthlyLimit == 0) return false; // Unlimited
      
      final usageStats = await getUsageStats();
      if (usageStats == null) return true; // First time user
      
      // Check if month changed
      final now = DateTime.now();
      if (usageStats.lastUsed.month != now.month || usageStats.lastUsed.year != now.year) {
        // Reset monthly usage
        return true;
      }
      
      return usageStats.monthlyMessagesUsed < monthlyLimit;
    } catch (e) {
      rethrow;
    }
  }

  /// Get remaining AI messages for user
  Future<int> getRemainingMessages() async {
    try {
      final subscription = await _getSubscription();
      if (subscription == null) return 0;
      
      final monthlyLimit = subscription['monthlyAIMessages'] as int? ?? 0;
      if (monthlyLimit == 0) return 999; // Unlimited
      
      final usageStats = await getUsageStats();
      if (usageStats == null) return monthlyLimit; // First time user
      
      // Check if month changed
      final now = DateTime.now();
      if (usageStats.lastUsed.month != now.month || usageStats.lastUsed.year != now.year) {
        // Month changed, reset count
        return monthlyLimit;
      }
      
      return (monthlyLimit - usageStats.monthlyMessagesUsed).clamp(0, monthlyLimit);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete old AI chat messages (cleanup)
  Future<void> deleteOldMessages(Duration olderThan) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      
      final query = _firestore
          .collection(_aiChatCollection)
          .doc(_userId)
          .collection('messages')
          .where('timestamp', isLessThan: cutoffDate);
      
      final docs = await query.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Private: Update usage statistics
  Future<void> _updateUsageStats(int tokens, String category) async {
    try {
      final now = DateTime.now();
      final statsRef = _firestore
          .collection(_usageStatsCollection)
          .doc(_userId);
      
      final doc = await statsRef.get();
      
      if (!doc.exists) {
        // Create new stats document
        await statsRef.set({
          'userId': _userId,
          'totalMessages': 1,
          'totalTokens': tokens,
          'monthlyMessagesUsed': 1,
          'monthlyTokensUsed': tokens,
          'topCategories': {category: 1},
          'lastUsed': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing stats
        final stats = AIUsageStats.fromFirestore(doc);
        final topCategories = Map<String, int>.from(stats.topCategories);
        topCategories[category] = (topCategories[category] ?? 0) + 1;
        
        // Check if month changed
        bool monthChanged = stats.lastUsed.month != now.month ||
            stats.lastUsed.year != now.year;
        
        await statsRef.update({
          'totalMessages': FieldValue.increment(1),
          'totalTokens': FieldValue.increment(tokens),
          'monthlyMessagesUsed': monthChanged ? 1 : FieldValue.increment(1),
          'monthlyTokensUsed': monthChanged ? tokens : FieldValue.increment(tokens),
          'topCategories': topCategories,
          'lastUsed': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Private: Get subscription data
  Future<Map<String, dynamic>?> _getSubscription() async {
    try {
      final doc = await _firestore
          .collection('user_subscriptions')
          .doc(_userId)
          .get();
      
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      return null; // Silently fail
    }
  }
}
