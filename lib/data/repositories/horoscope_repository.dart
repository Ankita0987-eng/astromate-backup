import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/horoscope_data.dart';

/// Repository for managing horoscope data
class HoroscopeRepository {
  HoroscopeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _horoscopesCollection = 'horoscopes';
  static const String _userHoroscopesCollection = 'user_horoscopes';

  /// Get daily horoscope for a zodiac sign
  Future<HoroscopeData?> getDailyHoroscope(String zodiacSign) async {
    try {
      final doc = await _firestore
          .collection(_horoscopesCollection)
          .where('zodiacSign', isEqualTo: zodiacSign)
          .where('periodType', isEqualTo: 'daily')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;
      final data = doc.docs.first.data();
      data['id'] = doc.docs.first.id;
      return HoroscopeData.fromFirestore(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get weekly horoscope for a zodiac sign
  Future<HoroscopeData?> getWeeklyHoroscope(String zodiacSign) async {
    try {
      final doc = await _firestore
          .collection(_horoscopesCollection)
          .where('zodiacSign', isEqualTo: zodiacSign)
          .where('periodType', isEqualTo: 'weekly')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;
      final data = doc.docs.first.data();
      data['id'] = doc.docs.first.id;
      return HoroscopeData.fromFirestore(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get monthly horoscope for a zodiac sign
  Future<HoroscopeData?> getMonthlyHoroscope(String zodiacSign) async {
    try {
      final doc = await _firestore
          .collection(_horoscopesCollection)
          .where('zodiacSign', isEqualTo: zodiacSign)
          .where('periodType', isEqualTo: 'monthly')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;
      final data = doc.docs.first.data();
      data['id'] = doc.docs.first.id;
      return HoroscopeData.fromFirestore(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get yearly horoscope for a zodiac sign
  Future<HoroscopeData?> getYearlyHoroscope(String zodiacSign) async {
    try {
      final doc = await _firestore
          .collection(_horoscopesCollection)
          .where('zodiacSign', isEqualTo: zodiacSign)
          .where('periodType', isEqualTo: 'yearly')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;
      final data = doc.docs.first.data();
      data['id'] = doc.docs.first.id;
      return HoroscopeData.fromFirestore(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's horoscope reading
  Future<UserHoroscope?> getUserHoroscope() async {
    try {
      final doc = await _firestore
          .collection(_userHoroscopesCollection)
          .doc(_userId)
          .get();

      if (!doc.exists) return null;
      return UserHoroscope.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Save user's horoscope reading
  Future<UserHoroscope> saveUserHoroscope(UserHoroscope horoscope) async {
    try {
      final data = horoscope.toMap();
      await _firestore
          .collection(_userHoroscopesCollection)
          .doc(_userId)
          .set(data, SetOptions(merge: true));
      return horoscope;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream user's horoscope updates
  Stream<UserHoroscope?> watchUserHoroscope() {
    return _firestore
        .collection(_userHoroscopesCollection)
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.exists ? UserHoroscope.fromFirestore(doc) : null);
  }

  /// Get horoscope history for a zodiac sign
  Future<List<HoroscopeData>> getHoroscopeHistory(
    String zodiacSign, {
    String periodType = 'daily',
    int limit = 30,
  }) async {
    try {
      final docs = await _firestore
          .collection(_horoscopesCollection)
          .where('zodiacSign', isEqualTo: zodiacSign)
          .where('periodType', isEqualTo: periodType)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return HoroscopeData.fromFirestore(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search horoscopes by text
  Future<List<HoroscopeData>> searchHoroscopes(String query) async {
    try {
      final docs = await _firestore
          .collection(_horoscopesCollection)
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: query + 'z')
          .limit(20)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return HoroscopeData.fromFirestore(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
