import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PersonInput extends Equatable {
  const PersonInput({
    required this.name,
    this.gender,
    required this.birthDate,
    this.birthTime,
    this.birthLocation,
    this.birthLocationCity,
    this.birthLocationCountry,
    this.birthLocationLatitude,
    this.birthLocationLongitude,
    required this.zodiacSign,
  });

  final String name;
  final String? gender;
  final DateTime birthDate;
  final DateTime? birthTime;
  final String? birthLocation;
  final String? birthLocationCity;
  final String? birthLocationCountry;
  final double? birthLocationLatitude;
  final double? birthLocationLongitude;
  final String zodiacSign;

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender,
        'birthDate': Timestamp.fromDate(birthDate),
        'birthTime': birthTime != null ? Timestamp.fromDate(birthTime!) : null,
        'birthLocation': birthLocation,
        'birthLocationCity': birthLocationCity,
        'birthLocationCountry': birthLocationCountry,
        'birthLocationLatitude': birthLocationLatitude,
        'birthLocationLongitude': birthLocationLongitude,
        'zodiacSign': zodiacSign,
      };

  factory PersonInput.fromMap(Map<String, dynamic> data) => PersonInput(
        name: data['name'] as String? ?? '',
        gender: data['gender'] as String?,
        birthDate: (data['birthDate'] as Timestamp).toDate(),
        birthTime: (data['birthTime'] as Timestamp?)?.toDate(),
        birthLocation: data['birthLocation'] as String?,
        birthLocationCity: data['birthLocationCity'] as String?,
        birthLocationCountry: data['birthLocationCountry'] as String?,
        birthLocationLatitude: (data['birthLocationLatitude'] as num?)?.toDouble(),
        birthLocationLongitude: (data['birthLocationLongitude'] as num?)?.toDouble(),
        zodiacSign: data['zodiacSign'] as String? ?? '',
      );

  @override
  List<Object?> get props => [name, birthDate, zodiacSign];
}

class CompatibilityReport extends Equatable {
  const CompatibilityReport({
    required this.id,
    required this.userId,
    required this.personA,
    required this.personB,
    required this.overallScore,
    required this.emotionalScore,
    required this.communicationScore,
    required this.romanticScore,
    required this.longTermScore,
    required this.soulmatePercentage,
    required this.twinFlameScore,
    required this.strengths,
    required this.weaknesses,
    required this.redFlags,
    required this.summary,
    required this.createdAt,
    this.isPremiumReport = false,
  });

  final String id;
  final String userId;
  final PersonInput personA;
  final PersonInput personB;
  final int overallScore;
  final int emotionalScore;
  final int communicationScore;
  final int romanticScore;
  final int longTermScore;
  final int soulmatePercentage;
  final int twinFlameScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> redFlags;
  final String summary;
  final DateTime createdAt;
  final bool isPremiumReport;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'personA': personA.toMap(),
        'personB': personB.toMap(),
        'overallScore': overallScore,
        'emotionalScore': emotionalScore,
        'communicationScore': communicationScore,
        'romanticScore': romanticScore,
        'longTermScore': longTermScore,
        'soulmatePercentage': soulmatePercentage,
        'twinFlameScore': twinFlameScore,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'redFlags': redFlags,
        'summary': summary,
        'createdAt': Timestamp.fromDate(createdAt),
        'isPremiumReport': isPremiumReport,
      };

  factory CompatibilityReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompatibilityReport(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      personA: PersonInput.fromMap(data['personA'] as Map<String, dynamic>),
      personB: PersonInput.fromMap(data['personB'] as Map<String, dynamic>),
      overallScore: data['overallScore'] as int? ?? 0,
      emotionalScore: data['emotionalScore'] as int? ?? 0,
      communicationScore: data['communicationScore'] as int? ?? 0,
      romanticScore: data['romanticScore'] as int? ?? 0,
      longTermScore: data['longTermScore'] as int? ?? 0,
      soulmatePercentage: data['soulmatePercentage'] as int? ?? 0,
      twinFlameScore: data['twinFlameScore'] as int? ?? 0,
      strengths: List<String>.from(data['strengths'] as List? ?? []),
      weaknesses: List<String>.from(data['weaknesses'] as List? ?? []),
      redFlags: List<String>.from(data['redFlags'] as List? ?? []),
      summary: data['summary'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremiumReport: data['isPremiumReport'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, overallScore, createdAt];
}
