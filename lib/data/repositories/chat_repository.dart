import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _chats(String uid) =>
      _firestore.collection('users').doc(uid).collection('ai_chats');

  Stream<List<AiChatSession>> watchSessions(String uid) {
    return _chats(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final sessions = <AiChatSession>[];
      for (final doc in snap.docs) {
        final messagesSnap = await doc.reference
            .collection('messages')
            .orderBy('createdAt')
            .get();
        final messages = messagesSnap.docs
            .map((m) => ChatMessage.fromMap(m.id, m.data()))
            .toList();
        final data = doc.data();
        sessions.add(AiChatSession(
          id: doc.id,
          userId: uid,
          title: data['title'] as String? ?? 'Cosmic Chat',
          messages: messages,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      return sessions;
    });
  }

  Future<String> createSession(String uid, String title) async {
    final id = _uuid.v4();
    await _chats(uid).doc(id).set({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> addMessage({
    required String uid,
    required String chatId,
    required ChatMessage message,
  }) async {
    await _chats(uid).doc(chatId).collection('messages').doc(message.id).set(
          message.toMap(),
        );
    await _chats(uid).doc(chatId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ChatMessage>> getMessages(String uid, String chatId) async {
    final snap = await _chats(uid)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((m) => ChatMessage.fromMap(m.id, m.data())).toList();
  }
}
