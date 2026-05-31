import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Match profile used for swipe matching.
class MatchProfile extends Equatable {
  const MatchProfile({
    required this.userId,
    required this.displayName,
    required this.age,
    required this.gender,
    required this.location,
    required this.photoUrls,
    required this.zodiacSign,
    required this.moonSign,
    required this.ascendant,
    required this.interests,
    required this.bio,
    required this.relationshipGoal,
    required this.isVerified,
    required this.lastActive,
    required this.createdAt,
  });

  final String userId;
  final String displayName;
  final int age;
  final String gender;
  final String location;
  final List<String> photoUrls;
  final String zodiacSign;
  final String moonSign;
  final String ascendant;
  final List<String> interests;
  final String bio;
  final String relationshipGoal;
  final bool isVerified;
  final DateTime lastActive;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'age': age,
      'gender': gender,
      'location': location,
      'photoUrls': photoUrls,
      'zodiacSign': zodiacSign,
      'moonSign': moonSign,
      'ascendant': ascendant,
      'interests': interests,
      'bio': bio,
      'relationshipGoal': relationshipGoal,
      'isVerified': isVerified,
      'lastActive': Timestamp.fromDate(lastActive),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MatchProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchProfile(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? '',
      age: data['age'] as int? ?? 0,
      gender: data['gender'] as String? ?? '',
      location: data['location'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      zodiacSign: data['zodiacSign'] as String? ?? '',
      moonSign: data['moonSign'] as String? ?? '',
      ascendant: data['ascendant'] as String? ?? '',
      interests: List<String>.from(data['interests'] as List? ?? []),
      bio: data['bio'] as String? ?? '',
      relationshipGoal: data['relationshipGoal'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, displayName, zodiacSign];
}

/// Represents a like/dislike/super-like action.
class MatchAction extends Equatable {
  const MatchAction({
    required this.id,
    required this.userId,
    required this.targetUserId,
    required this.actionType, // like, dislike, superlike
    required this.compatibilityScore,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String targetUserId;
  final String actionType;
  final int compatibilityScore;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'targetUserId': targetUserId,
      'actionType': actionType,
      'compatibilityScore': compatibilityScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MatchAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchAction(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      targetUserId: data['targetUserId'] as String? ?? '',
      actionType: data['actionType'] as String? ?? 'like',
      compatibilityScore: data['compatibilityScore'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, targetUserId, actionType];
}

/// Represents a match (mutual like).
class Match extends Equatable {
  const Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.compatibilityScore,
    required this.compatibilityPercentage,
    required this.matchedAt,
    this.messageCount = 0,
    this.lastMessageAt,
  });

  final String id;
  final String userId1;
  final String userId2;
  final int compatibilityScore;
  final int compatibilityPercentage;
  final DateTime matchedAt;
  final int messageCount;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toMap() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'compatibilityScore': compatibilityScore,
      'compatibilityPercentage': compatibilityPercentage,
      'matchedAt': Timestamp.fromDate(matchedAt),
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    };
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      userId1: data['userId1'] as String? ?? '',
      userId2: data['userId2'] as String? ?? '',
      compatibilityScore: data['compatibilityScore'] as int? ?? 0,
      compatibilityPercentage: data['compatibilityPercentage'] as int? ?? 0,
      matchedAt: (data['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] as int? ?? 0,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, userId1, userId2, matchedAt];
}
