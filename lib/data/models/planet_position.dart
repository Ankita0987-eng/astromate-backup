import 'package:equatable/equatable.dart';

/// A single planet's position returned by the AstrologyAPI `/planets` endpoint.
class PlanetPosition extends Equatable {
  const PlanetPosition({
    required this.planet,
    required this.sign,
    required this.degree,
    required this.isRetrograde,
  });

  final String planet;
  final String sign;

  /// Normalised degree within the sign (0.0–359.99).
  final double degree;

  final bool isRetrograde;

  factory PlanetPosition.fromJson(Map<String, dynamic> json) {
    // AstrologyAPI returns isRetro as either a bool or the string "true"/"false".
    final retroRaw = json['isRetro'];
    final isRetrograde =
        retroRaw == true || retroRaw.toString().toLowerCase() == 'true';

    return PlanetPosition(
      planet: json['name'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
      degree: (json['normDegree'] as num?)?.toDouble() ?? 0.0,
      isRetrograde: isRetrograde,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': planet,
        'sign': sign,
        'normDegree': degree,
        'isRetro': isRetrograde,
      };

  @override
  List<Object?> get props => [planet, sign, degree, isRetrograde];
}
