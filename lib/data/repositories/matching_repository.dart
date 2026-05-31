import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_profile.dart';

/// Repository for managing matching and swipe data in Firestore.
class MatchingRepository {
  MatchingRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _matchProfilesCollection = 'match_profiles';
  static const String _matchActionsCollection = 'match_actions';
  static const String _matchesCollection = 'matches';

  /// Save a match profile
  Future<MatchProfile> saveMatchProfile(MatchProfile profile) async {
    final docRef = _firestore
        .collection(_matchProfilesCollection)
        .doc(profile.userId);
    
    await docRef.set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  /// Get a match profile by user ID
  Future<MatchProfile?> getMatchProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_matchProfilesCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) return null;
      return MatchProfile.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all match profiles with optional filters
  Future<List<MatchProfile>> getMatchProfiles({
    String? genderFilter,
    int? ageMin,
    int? ageMax,
    String? zodiacSign,
    List<String>? interests,
  }) async {
    try {
      Query query = _firestore.collection(_matchProfilesCollection);
      
      if (genderFilter != null) {
        query = query.where('gender', isEqualTo: genderFilter);
      }
      
      if (ageMin != null) {
        query = query.where('age', isGreaterThanOrEqualTo: ageMin);
      }
      
      if (ageMax != null) {
        query = query.where('age', isLessThanOrEqualTo: ageMax);
      }
      
      if (zodiacSign != null) {
        query = query.where('zodiacSign', isEqualTo: zodiacSign);
      }
      
      final docs = await query.limit(50).get();
      return docs.docs.map((doc) => MatchProfile.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Record a match action (like, dislike, super-like)
  Future<MatchAction> recordMatchAction(
    String targetUserId,
    String actionType,
    int compatibilityScore,
  ) async {
    try {
      final docRef = _firestore
          .collection(_matchActionsCollection)
          .doc();
      
      final action = MatchAction(
        id: docRef.id,
        userId: _userId,
        targetUserId: targetUserId,
        actionType: actionType,
        compatibilityScore: compatibilityScore,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(action.toMap());
      
      // Check for mutual like
      if (actionType == 'like' || actionType == 'superlike') {
        await _checkAndCreateMatch(targetUserId, compatibilityScore);
      }
      
      return action;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's match actions
  Future<List<MatchAction>> getUserMatchActions() async {
    try {
      final docs = await _firestore
          .collection(_matchActionsCollection)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      return docs.docs.map((doc) => MatchAction.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get matches for current user
  Future<List<Match>> getMatches() async {
    try {
      final docs = await _firestore
          .collection(_matchesCollection)
          .where('isActive', isEqualTo: true)
          .where(
            Filter.or(
              Filter('userId1', isEqualTo: _userId),
              Filter('userId2', isEqualTo: _userId),
            ),
          )
          .orderBy('lastMessageAt', descending: true)
          .get();
      
      return docs.docs.map((doc) => Match.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream matches for real-time updates
  Stream<List<Match>> watchMatches() {
    return _firestore
        .collection(_matchesCollection)
        .where('isActive', isEqualTo: true)
        .where(
          Filter.or(
            Filter('userId1', isEqualTo: _userId),
            Filter('userId2', isEqualTo: _userId),
          ),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromFirestore(doc))
            .toList());
  }

  /// Get a specific match
  Future<Match?> getMatch(String matchId) async {
    try {
      final doc = await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .get();
      
      if (!doc.exists) return null;
      return Match.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Update match info
  Future<void> updateMatch(Match match) async {
    try {
      await _firestore
          .collection(_matchesCollection)
          .doc(match.id)
          .set(match.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Unmatch (delete match)
  Future<void> unmatch(String matchId) async {
    try {
      await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .update({'isActive': false, 'unlockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      rethrow;
    }
  }

  /// Check if action exists towards user
  Future<MatchAction?> getMatchAction(
    String targetUserId,
    String actionType,
  ) async {
    try {
      final docs = await _firestore
          .collection(_matchActionsCollection)
          .where('userId', isEqualTo: _userId)
          .where('targetUserId', isEqualTo: targetUserId)
          .where('actionType', isEqualTo: actionType)
          .limit(1)
          .get();
      
      return docs.docs.isNotEmpty ? MatchAction.fromFirestore(docs.docs.first) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Private: Check for mutual like and create match
  Future<void> _checkAndCreateMatch(String targetUserId, int compatibilityScore) async {
    try {
      // Check if target user liked/super-liked current user
      final targetActionDocs = await _firestore
          .collection(_matchActionsCollection)
          .where('userId', isEqualTo: targetUserId)
          .where('targetUserId', isEqualTo: _userId)
          .where(
            Filter.or(
              Filter('actionType', isEqualTo: 'like'),
              Filter('actionType', isEqualTo: 'superlike'),
            ),
          )
          .limit(1)
          .get();
      
      if (targetActionDocs.docs.isNotEmpty) {
        // Mutual like found - create match
        final matchId = _firestore.collection(_matchesCollection).doc().id;
        final match = Match(
          id: matchId,
          userId1: _userId,
          userId2: targetUserId,
          compatibilityScore: compatibilityScore,
          compatibilityPercentage: (compatibilityScore.clamp(0, 100)),
          matchedAt: DateTime.now(),
        );
        
        await _firestore
            .collection(_matchesCollection)
            .doc(matchId)
            .set({
              ...match.toMap(),
              'isActive': true,
            });
      }
    } catch (e) {
      // Silent fail - don't interrupt the match action
    }
  }
}
