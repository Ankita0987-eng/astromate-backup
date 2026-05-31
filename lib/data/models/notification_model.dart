import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a notification to be shown to the user.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type, // match, message, horoscope, planetary, birthday
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionUrl': actionUrl,
    };
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'message',
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actionUrl: data['actionUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, createdAt];
}

/// User notification preferences.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.userId,
    required this.matchNotifications,
    required this.messageNotifications,
    required this.dailyHoroscopeNotifications,
    required this.planetaryTransitNotifications,
    required this.birthdayNotifications,
    required this.compatibilityAlerts,
    required this.subscriptionReminders,
    required this.generalNotifications,
    required this.quietHours, // e.g., "22:00-08:00"
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  final String userId;
  final bool matchNotifications;
  final bool messageNotifications;
  final bool dailyHoroscopeNotifications;
  final bool planetaryTransitNotifications;
  final bool birthdayNotifications;
  final bool compatibilityAlerts;
  final bool subscriptionReminders;
  final bool generalNotifications;
  final String quietHours;
  final bool soundEnabled;
  final bool vibrationEnabled;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'matchNotifications': matchNotifications,
      'messageNotifications': messageNotifications,
      'dailyHoroscopeNotifications': dailyHoroscopeNotifications,
      'planetaryTransitNotifications': planetaryTransitNotifications,
      'birthdayNotifications': birthdayNotifications,
      'compatibilityAlerts': compatibilityAlerts,
      'subscriptionReminders': subscriptionReminders,
      'generalNotifications': generalNotifications,
      'quietHours': quietHours,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPreferences(
      userId: doc.id,
      matchNotifications: data['matchNotifications'] as bool? ?? true,
      messageNotifications: data['messageNotifications'] as bool? ?? true,
      dailyHoroscopeNotifications: data['dailyHoroscopeNotifications'] as bool? ?? true,
      planetaryTransitNotifications: data['planetaryTransitNotifications'] as bool? ?? true,
      birthdayNotifications: data['birthdayNotifications'] as bool? ?? true,
      compatibilityAlerts: data['compatibilityAlerts'] as bool? ?? true,
      subscriptionReminders: data['subscriptionReminders'] as bool? ?? true,
      generalNotifications: data['generalNotifications'] as bool? ?? true,
      quietHours: data['quietHours'] as String? ?? '22:00-08:00',
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data['vibrationEnabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [userId, matchNotifications, messageNotifications];
}

/// Enhanced ChatMessage with more features.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.messageType, // text, image, voice, emoji_reaction
    required this.timestamp,
    required this.isRead,
    this.readAt,
    this.imageUrl,
    this.reactionEmoji,
    this.replyToId,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String messageType;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final String? imageUrl;
  final String? reactionEmoji;
  final String? replyToId;

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'reactionEmoji': reactionEmoji,
      'replyToId': replyToId,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      recipientId: data['recipientId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      messageType: data['messageType'] as String? ?? 'text',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'] as String?,
      reactionEmoji: data['reactionEmoji'] as String?,
      replyToId: data['replyToId'] as String?,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
    String? reactionEmoji,
    String? replyToId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      replyToId: replyToId ?? this.replyToId,
    );
  }

  @override
  List<Object?> get props => [id, senderId, recipientId, timestamp];
}

/// Represents a chat thread between two users.
class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId1;
  final String userId2;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatThread(
      id: doc.id,
      userId1: data['userId1'] as String? ?? '',
      userId2: data['userId2'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId1, userId2];
}
