import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'planet_position.dart';

/// Represents a birth chart with all astrological data.
class BirthChart extends Equatable {
  const BirthChart({
    required this.userId,
    required this.sunSign,
    required this.moonSign,
    required this.ascendant,
    required this.nakshatras,
    required this.planets,
    required this.houses,
    required this.aspects,
    required this.retrogradeSignatures,
    required this.cosmicEnergy,
    required this.birthDate,
    required this.birthTime,
    required this.birthLocation,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.rawData,
    required this.generatedAt,
    this.id,
    this.venusSign,
    this.mercurySign,
  });

  final String? id;
  final String userId;
  final String sunSign;
  final String moonSign;
  final String ascendant;
  final String? venusSign;
  final String? mercurySign;
  final Map<String, String> nakshatras; // planet -> nakshatra
  final Map<String, PlanetPosition> planets;
  final Map<String, HouseData> houses;
  final List<AspectData> aspects;
  final Map<String, bool> retrogradeSignatures;
  final double cosmicEnergy;
  final DateTime birthDate;
  final DateTime? birthTime;
  final String birthLocation;
  final double latitude;
  final double longitude;
  final double timezone;
  final Map<String, dynamic> rawData;
  final DateTime generatedAt;

  BirthChart copyWith({
    String? id,
    String? userId,
    String? sunSign,
    String? moonSign,
    String? ascendant,
    String? venusSign,
    String? mercurySign,
    Map<String, String>? nakshatras,
    Map<String, PlanetPosition>? planets,
    Map<String, HouseData>? houses,
    List<AspectData>? aspects,
    Map<String, bool>? retrogradeSignatures,
    double? cosmicEnergy,
    DateTime? birthDate,
    DateTime? birthTime,
    String? birthLocation,
    double? latitude,
    double? longitude,
    double? timezone,
    Map<String, dynamic>? rawData,
    DateTime? generatedAt,
  }) {
    return BirthChart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sunSign: sunSign ?? this.sunSign,
      moonSign: moonSign ?? this.moonSign,
      ascendant: ascendant ?? this.ascendant,
      venusSign: venusSign ?? this.venusSign,
      mercurySign: mercurySign ?? this.mercurySign,
      nakshatras: nakshatras ?? this.nakshatras,
      planets: planets ?? this.planets,
      houses: houses ?? this.houses,
      aspects: aspects ?? this.aspects,
      retrogradeSignatures: retrogradeSignatures ?? this.retrogradeSignatures,
      cosmicEnergy: cosmicEnergy ?? this.cosmicEnergy,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthLocation: birthLocation ?? this.birthLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      rawData: rawData ?? this.rawData,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sunSign': sunSign,
      'moonSign': moonSign,
      'ascendant': ascendant,
      'nakshatras': nakshatras,
      'planets': planets.map((k, v) => MapEntry(k, v.toMap())),
      'houses': houses.map((k, v) => MapEntry(k, v.toMap())),
      'aspects': aspects.map((a) => a.toMap()).toList(),
      'retrogradeSignatures': retrogradeSignatures,
      'cosmicEnergy': cosmicEnergy,
      'birthDate': Timestamp.fromDate(birthDate),
      'birthTime': birthTime != null ? Timestamp.fromDate(birthTime!) : null,
      'birthLocation': birthLocation,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'rawData': rawData,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory BirthChart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BirthChart(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      sunSign: data['sunSign'] as String? ?? '',
      moonSign: data['moonSign'] as String? ?? '',
      ascendant: data['ascendant'] as String? ?? '',
      nakshatras: Map<String, String>.from(data['nakshatras'] as Map? ?? {}),
      planets: (data['planets'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k as String, PlanetPosition.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      houses: (data['houses'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k as String, HouseData.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      aspects: (data['aspects'] as List?)?.map((a) => AspectData.fromMap(a as Map<String, dynamic>)).toList() ?? [],
      retrogradeSignatures: Map<String, bool>.from(data['retrogradeSignatures'] as Map? ?? {}),
      cosmicEnergy: (data['cosmicEnergy'] as num?)?.toDouble() ?? 0.0,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      birthTime: (data['birthTime'] as Timestamp?)?.toDate(),
      birthLocation: data['birthLocation'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (data['timezone'] as num?)?.toDouble() ?? 5.5,
      rawData: data['rawData'] as Map<String, dynamic>? ?? {},
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, sunSign, moonSign, ascendant, generatedAt];
}

/// Represents a house in the birth chart.
class HouseData extends Equatable {
  const HouseData({
    required this.number,
    required this.sign,
    required this.startDegree,
    required this.endDegree,
    required this.ruler,
    required this.planets,
  });

  final int number;
  final String sign;
  final double startDegree;
  final double endDegree;
  final String ruler;
  final List<String> planets;

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'sign': sign,
      'startDegree': startDegree,
      'endDegree': endDegree,
      'ruler': ruler,
      'planets': planets,
    };
  }

  factory HouseData.fromMap(Map<String, dynamic> data) {
    return HouseData(
      number: data['number'] as int? ?? 0,
      sign: data['sign'] as String? ?? '',
      startDegree: (data['startDegree'] as num?)?.toDouble() ?? 0.0,
      endDegree: (data['endDegree'] as num?)?.toDouble() ?? 0.0,
      ruler: data['ruler'] as String? ?? '',
      planets: List<String>.from(data['planets'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [number, sign, startDegree, endDegree];
}

/// Represents an aspect between two planets.
class AspectData extends Equatable {
  const AspectData({
    required this.planet1,
    required this.planet2,
    required this.type,
    required this.angle,
    required this.orb,
    required this.isExact,
    required this.interpretation,
  });

  final String planet1;
  final String planet2;
  final String type; // conjunction, sextile, square, trine, opposition
  final double angle;
  final double orb;
  final bool isExact;
  final String interpretation;

  Map<String, dynamic> toMap() {
    return {
      'planet1': planet1,
      'planet2': planet2,
      'type': type,
      'angle': angle,
      'orb': orb,
      'isExact': isExact,
      'interpretation': interpretation,
    };
  }

  factory AspectData.fromMap(Map<String, dynamic> data) {
    return AspectData(
      planet1: data['planet1'] as String? ?? '',
      planet2: data['planet2'] as String? ?? '',
      type: data['type'] as String? ?? '',
      angle: (data['angle'] as num?)?.toDouble() ?? 0.0,
      orb: (data['orb'] as num?)?.toDouble() ?? 0.0,
      isExact: data['isExact'] as bool? ?? false,
      interpretation: data['interpretation'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [planet1, planet2, type, angle];
}
