import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// Repository for managing messaging and notifications.
class MessagingRepository {
  MessagingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _messagesCollection = 'messages';
  static const String _threadsCollection = 'chat_threads';
  static const String _notificationsCollection = 'notifications';
  static const String _preferencesCollection = 'notification_preferences';

  /// Send a message
  Future<ChatMessage> sendMessage(
    String recipientId,
    String content, {
    String messageType = 'text',
    String? imageUrl,
  }) async {
    try {
      final threadId = _getThreadId(_userId, recipientId);
      final docRef = _firestore
          .collection(_threadsCollection)
          .doc(threadId)
          .collection(_messagesCollection)
          .doc();
      
      final message = ChatMessage(
        id: docRef.id,
        senderId: _userId,
        recipientId: recipientId,
        content: content,
        messageType: messageType,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
      );
      
      // Save message
      await docRef.set(message.toMap());
      
      // Update thread metadata
      await _updateThreadMetadata(threadId, _userId, recipientId, content);
      
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages between two users
  Future<List<ChatMessage>> getMessages(
    String otherUserId, {
    int limit = 50,
  }) async {
    try {
      final threadId = _getThreadId(_userId, otherUserId);
      
      final docs = await _firestore
          .collection(_threadsCollection)
          .doc(threadId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return docs.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream messages between two users (real-time)
  Stream<List<ChatMessage>> watchMessages(String otherUserId) {
    final threadId = _getThreadId(_userId, otherUserId);
    
    return _firestore
        .collection(_threadsCollection)
        .doc(threadId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }

  /// Mark message as read
  Future<void> markAsRead(String otherUserId, String messageId) async {
    try {
      final threadId = _getThreadId(_userId, otherUserId);
      
      await _firestore
          .collection(_threadsCollection)
          .doc(threadId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat threads for user
  Future<List<ChatThread>> getChatThreads({int limit = 50}) async {
    try {
      final docs = await _firestore
          .collection(_threadsCollection)
          .where(
            Filter.or(
              Filter('userId1', isEqualTo: _userId),
              Filter('userId2', isEqualTo: _userId),
            ),
          )
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      
      return docs.docs.map((doc) => ChatThread.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream chat threads (real-time)
  Stream<List<ChatThread>> watchChatThreads() {
    return _firestore
        .collection(_threadsCollection)
        .where(
          Filter.or(
            Filter('userId1', isEqualTo: _userId),
            Filter('userId2', isEqualTo: _userId),
          ),
        )
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatThread.fromFirestore(doc)).toList());
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final docs = await _firestore
          .collection(_threadsCollection)
          .where(
            Filter.or(
              Filter('userId1', isEqualTo: _userId),
              Filter('userId2', isEqualTo: _userId),
            ),
          )
          .get();
      
      int totalUnread = 0;
      for (final doc in docs.docs) {
        final thread = ChatThread.fromFirestore(doc);
        totalUnread += thread.unreadCount;
      }
      
      return totalUnread;
    } catch (e) {
      rethrow;
    }
  }

  /// Send a notification
  Future<AppNotification> sendNotification(
    String userId,
    String title,
    String body,
    String type, {
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      final docRef = _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection('all')
          .doc();
      
      final notification = AppNotification(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
      );
      
      await docRef.set(notification.toMap());
      return notification;
    } catch (e) {
      rethrow;
    }
  }

  /// Get notifications for user
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_notificationsCollection)
          .doc(_userId)
          .collection('all');
      
      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }
      
      final docs = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return docs.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream notifications (real-time)
  Stream<List<AppNotification>> watchNotifications() {
    return _firestore
        .collection(_notificationsCollection)
        .doc(_userId)
        .collection('all')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(_userId)
          .collection('all')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences?> getPreferences() async {
    try {
      final doc = await _firestore
          .collection(_preferencesCollection)
          .doc(_userId)
          .get();
      
      if (!doc.exists) return null;
      return NotificationPreferences.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(_userId)
          .set(preferences.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Helper: Generate consistent thread ID
  String _getThreadId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Helper: Update thread metadata
  Future<void> _updateThreadMetadata(
    String threadId,
    String senderId,
    String recipientId,
    String lastMessage,
  ) async {
    try {
      final docRef = _firestore.collection(_threadsCollection).doc(threadId);
      
      final doc = await docRef.get();
      if (!doc.exists) {
        // Create new thread
        await docRef.set({
          'userId1': senderId,
          'userId2': recipientId,
          'lastMessage': lastMessage,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unreadCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing thread
        await docRef.update({
          'lastMessage': lastMessage,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
