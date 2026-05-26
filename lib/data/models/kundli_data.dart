import 'package:equatable/equatable.dart';

/// Vedic birth chart data returned by the AstrologyAPI `/birth_details` endpoint.
class KundliData extends Equatable {
  const KundliData({
    required this.sunSign,
    required this.moonSign,
    required this.ascendant,
    required this.nakshatra,
  });

  final String sunSign;
  final String moonSign;
  final String ascendant;
  final String nakshatra;

  factory KundliData.fromJson(Map<String, dynamic> json) => KundliData(
        sunSign: json['sun_sign'] as String? ?? '',
        moonSign: json['moon_sign'] as String? ?? '',
        ascendant: json['ascendant'] as String? ?? '',
        nakshatra: json['nakshatra'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'sun_sign': sunSign,
        'moon_sign': moonSign,
        'ascendant': ascendant,
        'nakshatra': nakshatra,
      };

  @override
  List<Object?> get props => [sunSign, moonSign, ascendant, nakshatra];
}
