import 'package:equatable/equatable.dart';

class DailyHoroscope extends Equatable {
  const DailyHoroscope({
    required this.zodiacSign,
    required this.date,
    required this.loveHoroscope,
    required this.careerHoroscope,
    required this.moodInsight,
    required this.loveEnergy,
    required this.cosmicEnergy,
    required this.luckyNumber,
    required this.luckyColor,
  });

  final String zodiacSign;
  final String date;
  final String loveHoroscope;
  final String careerHoroscope;
  final String moodInsight;
  final int loveEnergy;
  final String cosmicEnergy;
  final int luckyNumber;
  final String luckyColor;

  @override
  List<Object?> get props => [zodiacSign, date];
}
