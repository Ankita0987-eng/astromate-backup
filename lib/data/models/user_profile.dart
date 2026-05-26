import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.gender,
    this.birthDate,
    this.birthTime,
    this.birthLocation,
    this.birthLocationCity,
    this.birthLocationCountry,
    this.birthLocationLatitude,
    this.birthLocationLongitude,
    this.relationshipStatus,
    this.interests = const [],
    this.zodiacSign,
    this.photoUrl,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.createdAt,
    this.updatedAt,
    this.fcmToken,
    this.dailyChecksUsed = 0,
    this.aiMessagesUsed = 0,
    this.lastUsageDate,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? gender;
  final DateTime? birthDate;
  final DateTime? birthTime;
  final String? birthLocation;
  final String? birthLocationCity;
  final String? birthLocationCountry;
  final double? birthLocationLatitude;
  final double? birthLocationLongitude;
  final String? relationshipStatus;
  final List<String> interests;
  final String? zodiacSign;
  final String? photoUrl;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;
  final int dailyChecksUsed;
  final int aiMessagesUsed;
  final String? lastUsageDate;

  bool get isProfileComplete =>
      displayName.isNotEmpty &&
      birthDate != null &&
      birthLocation != null &&
      zodiacSign != null;

  UserProfile copyWith({
    String? displayName,
    String? gender,
    DateTime? birthDate,
    DateTime? birthTime,
    String? birthLocation,
    String? birthLocationCity,
    String? birthLocationCountry,
    double? birthLocationLatitude,
    double? birthLocationLongitude,
    String? relationshipStatus,
    List<String>? interests,
    String? zodiacSign,
    String? photoUrl,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? fcmToken,
    int? dailyChecksUsed,
    int? aiMessagesUsed,
    String? lastUsageDate,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthLocation: birthLocation ?? this.birthLocation,
      birthLocationCity: birthLocationCity ?? this.birthLocationCity,
      birthLocationCountry: birthLocationCountry ?? this.birthLocationCountry,
      birthLocationLatitude: birthLocationLatitude ?? this.birthLocationLatitude,
      birthLocationLongitude: birthLocationLongitude ?? this.birthLocationLongitude,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      interests: interests ?? this.interests,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      fcmToken: fcmToken ?? this.fcmToken,
      dailyChecksUsed: dailyChecksUsed ?? this.dailyChecksUsed,
      aiMessagesUsed: aiMessagesUsed ?? this.aiMessagesUsed,
      lastUsageDate: lastUsageDate ?? this.lastUsageDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'birthTime': birthTime != null ? Timestamp.fromDate(birthTime!) : null,
      'birthLocation': birthLocation,
      'birthLocationCity': birthLocationCity,
      'birthLocationCountry': birthLocationCountry,
      'birthLocationLatitude': birthLocationLatitude,
      'birthLocationLongitude': birthLocationLongitude,
      'relationshipStatus': relationshipStatus,
      'interests': interests,
      'zodiacSign': zodiacSign,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'premiumExpiresAt':
          premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
      'dailyChecksUsed': dailyChecksUsed,
      'aiMessagesUsed': aiMessagesUsed,
      'lastUsageDate': lastUsageDate,
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      gender: data['gender'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      birthTime: (data['birthTime'] as Timestamp?)?.toDate(),
      birthLocation: data['birthLocation'] as String?,
      birthLocationCity: data['birthLocationCity'] as String?,
      birthLocationCountry: data['birthLocationCountry'] as String?,
      birthLocationLatitude: (data['birthLocationLatitude'] as num?)?.toDouble(),
      birthLocationLongitude: (data['birthLocationLongitude'] as num?)?.toDouble(),
      relationshipStatus: data['relationshipStatus'] as String?,
      interests: List<String>.from(data['interests'] as List? ?? []),
      zodiacSign: data['zodiacSign'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      premiumExpiresAt: (data['premiumExpiresAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
      dailyChecksUsed: data['dailyChecksUsed'] as int? ?? 0,
      aiMessagesUsed: data['aiMessagesUsed'] as int? ?? 0,
      lastUsageDate: data['lastUsageDate'] as String?,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, isPremium];
}
