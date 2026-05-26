import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/zodiac_utils.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> createOrUpdateProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserProfile> ensureProfile({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    final existing = await getProfile(uid);
    if (existing != null) return existing;

    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createOrUpdateProfile(profile);
    return profile;
  }

  Future<UserProfile> saveProfileSetup({
    required String uid,
    required String displayName,
    String? gender,
    required DateTime birthDate,
    DateTime? birthTime,
    required String birthLocation,
    String? birthLocationCity,
    String? birthLocationCountry,
    double? birthLocationLatitude,
    double? birthLocationLongitude,
    String? relationshipStatus,
    List<String>? interests,
  }) async {
    final sign = ZodiacUtils.signFromDate(birthDate);
    final profile = (await getProfile(uid))?.copyWith(
          displayName: displayName,
          gender: gender,
          birthDate: birthDate,
          birthTime: birthTime,
          birthLocation: birthLocation,
          birthLocationCity: birthLocationCity,
          birthLocationCountry: birthLocationCountry,
          birthLocationLatitude: birthLocationLatitude,
          birthLocationLongitude: birthLocationLongitude,
          relationshipStatus: relationshipStatus,
          interests: interests,
          zodiacSign: sign,
        ) ??
        UserProfile(
          uid: uid,
          email: '',
          displayName: displayName,
          gender: gender,
          birthDate: birthDate,
          birthTime: birthTime,
          birthLocation: birthLocation,
          birthLocationCity: birthLocationCity,
          birthLocationCountry: birthLocationCountry,
          birthLocationLatitude: birthLocationLatitude,
          birthLocationLongitude: birthLocationLongitude,
          relationshipStatus: relationshipStatus,
          interests: interests ?? [],
          zodiacSign: sign,
        );
    await createOrUpdateProfile(profile);
    return profile;
  }

  Future<bool> canRunCompatibilityCheck(UserProfile profile) async {
    if (profile.isPremium) return true;
    final today = AppDateUtils.todayKey();
    if (profile.lastUsageDate != today) {
      await updateProfileFields(profile.uid, {
        'dailyChecksUsed': 0,
        'lastUsageDate': today,
      });
      return true;
    }
    return profile.dailyChecksUsed < AppConstants.freeCompatibilityChecksPerDay;
  }

  Future<void> incrementCompatibilityUsage(String uid) async {
    final today = AppDateUtils.todayKey();
    final profile = await getProfile(uid);
    if (profile == null) return;
    final reset = profile.lastUsageDate != today;
    await updateProfileFields(uid, {
      'dailyChecksUsed': reset ? 1 : FieldValue.increment(1),
      'lastUsageDate': today,
    });
  }

  Future<bool> canSendAiMessage(UserProfile profile) async {
    if (profile.isPremium) return true;
    final today = AppDateUtils.todayKey();
    if (profile.lastUsageDate != today) return true;
    return profile.aiMessagesUsed < AppConstants.freeAiMessagesPerDay;
  }

  Future<void> incrementAiUsage(String uid) async {
    final today = AppDateUtils.todayKey();
    final profile = await getProfile(uid);
    if (profile == null) return;
    final reset = profile.lastUsageDate != today;
    await updateProfileFields(uid, {
      'aiMessagesUsed': reset ? 1 : FieldValue.increment(1),
      'lastUsageDate': today,
    });
  }

  Future<void> setPremium(String uid, {required bool isPremium, DateTime? expiresAt}) {
    return updateProfileFields(uid, {
      'isPremium': isPremium,
      'premiumExpiresAt':
          expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    });
  }

  Future<void> updateFcmToken(String uid, String token) {
    return updateProfileFields(uid, {'fcmToken': token});
  }

  Future<void> deleteUserData(String uid) async {
    final batch = _firestore.batch();
    final userRef = _users.doc(uid);
    final reports = await userRef.collection('compatibility_reports').get();
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }
    final chats = await userRef.collection('ai_chats').get();
    for (final doc in chats.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(userRef);
    await batch.commit();
  }
}
