import 'package:equatable/equatable.dart';

/// Represents a planet position in the birth chart with detailed astrological data.
class PlanetPosition extends Equatable {
  const PlanetPosition({
    required this.name,
    required this.sign,
    required this.degree,
    required this.minutes,
    required this.seconds,
    required this.isRetrograde,
    required this.house,
    required this.longitude,
    required this.latitude,
    required this.speed,
    required this.aspectScore,
    required this.interpretation,
  });

  final String name;
  final String sign;
  final double degree;
  final int minutes;
  final int seconds;
  final bool isRetrograde;
  final int house;
  final double longitude;
  final double latitude;
  final double speed;
  final int aspectScore; // 0-100
  final String interpretation;

  double get totalDegree => degree + (minutes / 60) + (seconds / 3600);

  factory PlanetPosition.fromJson(Map<String, dynamic> json) {
    final retroRaw = json['isRetro'];
    final isRetrograde = retroRaw == true || retroRaw.toString().toLowerCase() == 'true';
    
    return PlanetPosition(
      name: json['name'] as String? ?? json['planet'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
      degree: (json['degree'] as num? ?? json['normDegree'] as num?)?.toDouble() ?? 0.0,
      minutes: json['minutes'] as int? ?? 0,
      seconds: json['seconds'] as int? ?? 0,
      isRetrograde: isRetrograde,
      house: json['house'] as int? ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      aspectScore: json['aspectScore'] as int? ?? 50,
      interpretation: json['interpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sign': sign,
        'degree': degree,
        'minutes': minutes,
        'seconds': seconds,
        'isRetrograde': isRetrograde,
        'house': house,
        'longitude': longitude,
        'latitude': latitude,
        'speed': speed,
        'aspectScore': aspectScore,
        'interpretation': interpretation,
      };

  Map<String, dynamic> toMap() => toJson();

  factory PlanetPosition.fromMap(Map<String, dynamic> data) => PlanetPosition.fromJson(data);

  @override
  List<Object?> get props => [name, sign, degree, isRetrograde, house, aspectScore];
}
