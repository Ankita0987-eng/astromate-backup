import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Horoscope data for different time periods (daily, weekly, monthly, yearly).
class HoroscopeData extends Equatable {
  const HoroscopeData({
    required this.id,
    required this.zodiacSign,
    required this.periodType,
    required this.text,
    required this.luckyNumber,
    required this.luckyColor,
    required this.luckyGemstone,
    required this.moodScore,
    required this.energyScore,
    required this.loveScore,
    required this.healthScore,
    required this.wealthScore,
    required this.date,
    required this.expiresAt,
  });

  final String id;
  final String zodiacSign;
  final String periodType;
  final String text;
  final int luckyNumber;
  final String luckyColor;
  final String luckyGemstone;
  final int moodScore;
  final int energyScore;
  final int loveScore;
  final int healthScore;
  final int wealthScore;
  final DateTime date;
  final DateTime expiresAt;

  Map<String, dynamic> toMap() {
    return {
      'zodiacSign': zodiacSign,
      'periodType': periodType,
      'text': text,
      'luckyNumber': luckyNumber,
      'luckyColor': luckyColor,
      'luckyGemstone': luckyGemstone,
      'moodScore': moodScore,
      'energyScore': energyScore,
      'loveScore': loveScore,
      'healthScore': healthScore,
      'wealthScore': wealthScore,
      'date': Timestamp.fromDate(date),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory HoroscopeData.fromFirestore(Map<String, dynamic> data) {
    return HoroscopeData(
      id: data['id'] as String? ?? '',
      zodiacSign: data['zodiacSign'] as String? ?? '',
      periodType: data['periodType'] as String? ?? 'daily',
      text: data['text'] as String? ?? '',
      luckyNumber: data['luckyNumber'] as int? ?? 0,
      luckyColor: data['luckyColor'] as String? ?? '',
      luckyGemstone: data['luckyGemstone'] as String? ?? '',
      moodScore: data['moodScore'] as int? ?? 5,
      energyScore: data['energyScore'] as int? ?? 5,
      loveScore: data['loveScore'] as int? ?? 5,
      healthScore: data['healthScore'] as int? ?? 5,
      wealthScore: data['wealthScore'] as int? ?? 5,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
    );
  }

  factory HoroscopeData.fromDocSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return HoroscopeData.fromFirestore(data);
  }

  @override
  List<Object?> get props => [id, zodiacSign, periodType, date];
}

/// Represents a horoscope reading for a user with daily cosmic insights.
class UserHoroscope extends Equatable {
  const UserHoroscope({
    required this.userId,
    required this.sunSignHoroscope,
    required this.moonSignHoroscope,
    required this.ascendantHoroscope,
    required this.generalMood,
    required this.generalEnergy,
    required this.predictedEvents,
    required this.warning,
    required this.affirmation,
    required this.lastUpdated,
  });

  final String userId;
  final HoroscopeData sunSignHoroscope;
  final HoroscopeData moonSignHoroscope;
  final HoroscopeData ascendantHoroscope;
  final int generalMood;
  final int generalEnergy;
  final List<String> predictedEvents;
  final String? warning;
  final String affirmation;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sunSignHoroscope': sunSignHoroscope.toMap(),
      'moonSignHoroscope': moonSignHoroscope.toMap(),
      'ascendantHoroscope': ascendantHoroscope.toMap(),
      'generalMood': generalMood,
      'generalEnergy': generalEnergy,
      'predictedEvents': predictedEvents,
      'warning': warning,
      'affirmation': affirmation,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserHoroscope.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserHoroscope(
      userId: doc.id,
      sunSignHoroscope: HoroscopeData.fromFirestore(
        (data['sunSignHoroscope'] as Map<String, dynamic>?) ?? {},
      ),
      moonSignHoroscope: HoroscopeData.fromFirestore(
        (data['moonSignHoroscope'] as Map<String, dynamic>?) ?? {},
      ),
      ascendantHoroscope: HoroscopeData.fromFirestore(
        (data['ascendantHoroscope'] as Map<String, dynamic>?) ?? {},
      ),
      generalMood: data['generalMood'] as int? ?? 5,
      generalEnergy: data['generalEnergy'] as int? ?? 5,
      predictedEvents: List<String>.from(data['predictedEvents'] as List? ?? []),
      warning: data['warning'] as String?,
      affirmation: data['affirmation'] as String? ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, generalMood, generalEnergy];
}
