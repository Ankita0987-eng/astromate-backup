import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/compatibility_report.dart';
import '../data/repositories/compatibility_repository.dart';
import '../data/services/astrology_service.dart';
import '../core/services/astrology_calculations.dart';
import '../data/models/birth_chart.dart';

/// Compatibility engine for calculating relationship scores
class CompatibilityEngine {
  /// Calculate detailed compatibility between two people
  static Future<CompatibilityReport> calculateCompatibility({
    required String userId,
    required PersonInput personA,
    required PersonInput personB,
    BirthChart? chartA,
    BirthChart? chartB,
  }) async {
    // Calculate base compatibility from zodiac signs
    int overall = AstrologyCalculations._getZodiacCompatibility(
      personA.zodiacSign,
      personB.zodiacSign,
    );

    // Calculate specific dimensions
    int emotionalScore = _calculateEmotionalScore(personA, personB);
    int communicationScore = _calculateCommunicationScore(personA, personB);
    int romanticScore = _calculateRomanticScore(personA, personB);
    int longTermScore = _calculateLongTermScore(personA, personB);

    // Calculate composite scores
    int soulmatePercentage = ((emotionalScore + romanticScore) ~/ 2).clamp(0, 100);
    int twinFlameScore = ((overall + longTermScore) ~/ 2).clamp(0, 100);

    // Determine strengths and weaknesses
    final strengths = _determineStrengths(
      emotionalScore,
      communicationScore,
      romanticScore,
      longTermScore,
    );

    final weaknesses = _determineWeaknesses(
      emotionalScore,
      communicationScore,
      romanticScore,
      longTermScore,
    );

    final redFlags = _determineRedFlags(personA, personB);

    final summary = _generateSummary(
      overall,
      personA.zodiacSign,
      personB.zodiacSign,
      strengths,
      weaknesses,
    );

    return CompatibilityReport(
      id: 'compat_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      personA: personA,
      personB: personB,
      overallScore: overall,
      emotionalScore: emotionalScore,
      communicationScore: communicationScore,
      romanticScore: romanticScore,
      longTermScore: longTermScore,
      soulmatePercentage: soulmatePercentage,
      twinFlameScore: twinFlameScore,
      strengths: strengths,
      weaknesses: weaknesses,
      redFlags: redFlags,
      summary: summary,
      createdAt: DateTime.now(),
      isPremiumReport: false,
    );
  }

  static int _calculateEmotionalScore(PersonInput personA, PersonInput personB) {
    // Water signs (Cancer, Scorpio, Pisces) are most emotionally compatible with each other
    const waterSigns = ['Cancer', 'Scorpio', 'Pisces'];
    const earthSigns = ['Taurus', 'Virgo', 'Capricorn'];

    bool aIsWater = waterSigns.contains(personA.zodiacSign);
    bool bIsWater = waterSigns.contains(personB.zodiacSign);
    bool aIsEarth = earthSigns.contains(personA.zodiacSign);
    bool bIsEarth = earthSigns.contains(personB.zodiacSign);

    if ((aIsWater && bIsWater) || (aIsEarth && bIsEarth)) {
      return 85;
    }

    return 60;
  }

  static int _calculateCommunicationScore(PersonInput personA, PersonInput personB) {
    // Air signs (Gemini, Libra, Aquarius) communicate best with each other
    const airSigns = ['Gemini', 'Libra', 'Aquarius'];

    bool aIsAir = airSigns.contains(personA.zodiacSign);
    bool bIsAir = airSigns.contains(personB.zodiacSign);

    if (aIsAir && bIsAir) {
      return 90;
    }

    return 65;
  }

  static int _calculateRomanticScore(PersonInput personA, PersonInput personB) {
    // Fire signs are passionate; water/earth signs are more stable
    const fireSigns = ['Aries', 'Leo', 'Sagittarius'];
    const waterSigns = ['Cancer', 'Scorpio', 'Pisces'];

    bool aIsFire = fireSigns.contains(personA.zodiacSign);
    bool bIsFire = fireSigns.contains(personB.zodiacSign);
    bool aIsWater = waterSigns.contains(personA.zodiacSign);
    bool bIsWater = waterSigns.contains(personB.zodiacSign);

    if ((aIsFire && bIsFire) || (aIsWater && bIsWater)) {
      return 80;
    }

    if ((aIsFire && bIsWater) || (aIsWater && bIsFire)) {
      return 70; // Fire and water can work
    }

    return 65;
  }

  static int _calculateLongTermScore(PersonInput personA, PersonInput personB) {
    // Earth signs are most stable for long-term
    const earthSigns = ['Taurus', 'Virgo', 'Capricorn'];

    bool aIsEarth = earthSigns.contains(personA.zodiacSign);
    bool bIsEarth = earthSigns.contains(personB.zodiacSign);

    if (aIsEarth && bIsEarth) {
      return 90;
    }

    return 65;
  }

  static List<String> _determineStrengths(
    int emotional,
    int communication,
    int romantic,
    int longTerm,
  ) {
    final strengths = <String>[];

    if (emotional > 75) {
      strengths.add('Deep emotional connection and understanding');
    }

    if (communication > 80) {
      strengths.add('Excellent communication and clarity');
    }

    if (romantic > 80) {
      strengths.add('Strong romantic attraction and passion');
    }

    if (longTerm > 85) {
      strengths.add('Excellent long-term stability and commitment');
    }

    if (strengths.isEmpty) {
      strengths.add('Potential for growth and learning together');
    }

    return strengths;
  }

  static List<String> _determineWeaknesses(
    int emotional,
    int communication,
    int romantic,
    int longTerm,
  ) {
    final weaknesses = <String>[];

    if (emotional < 60) {
      weaknesses.add('May struggle with emotional expression');
    }

    if (communication < 60) {
      weaknesses.add('Communication could be challenging');
    }

    if (romantic < 60) {
      weaknesses.add('Romantic connection might need work');
    }

    if (longTerm < 60) {
      weaknesses.add('Long-term compatibility requires effort');
    }

    if (weaknesses.isEmpty) {
      weaknesses.add('Occasional misunderstandings possible');
    }

    return weaknesses;
  }

  static List<String> _determineRedFlags(PersonInput personA, PersonInput personB) {
    final redFlags = <String>[];

    // Highly incompatible signs
    const incompatiblePairs = [
      ('Aries', 'Cancer'),
      ('Taurus', 'Sagittarius'),
      ('Gemini', 'Virgo'),
      ('Cancer', 'Aries'),
      ('Leo', 'Scorpio'),
      ('Virgo', 'Sagittarius'),
      ('Libra', 'Cancer'),
      ('Scorpio', 'Leo'),
      ('Sagittarius', 'Taurus'),
      ('Capricorn', 'Aries'),
      ('Aquarius', 'Taurus'),
      ('Pisces', 'Gemini'),
    ];

    for (final (sign1, sign2) in incompatiblePairs) {
      if ((personA.zodiacSign == sign1 && personB.zodiacSign == sign2) ||
          (personA.zodiacSign == sign2 && personB.zodiacSign == sign1)) {
        redFlags.add('⚠️ Astrologically incompatible sign pair');
      }
    }

    return redFlags;
  }

  static String _generateSummary(
    int overall,
    String signA,
    String signB,
    List<String> strengths,
    List<String> weaknesses,
  ) {
    if (overall >= 80) {
      return '$signA and $signB make an excellent match! Your connection is marked by ${strengths.isNotEmpty ? strengths.first.toLowerCase() : "natural harmony"}. ${weaknesses.isNotEmpty ? "However, ${weaknesses.first.toLowerCase()}" : ""}.';
    } else if (overall >= 60) {
      return '$signA and $signB can create a great relationship with effort. While you have ${strengths.isNotEmpty ? strengths.first.toLowerCase() : "positive qualities"}, ${weaknesses.isNotEmpty ? weaknesses.first.toLowerCase() : "some challenges"} may arise.';
    } else {
      return '$signA and $signB will need to work actively on understanding each other. With patience and communication, a relationship can develop, though it may require more effort than typical pairings.';
    }
  }
}

/// Repository for compatibility operations
class CompatibilityRepository {
  final AstrologyService _astrologyService;

  CompatibilityRepository({AstrologyService? astrologyService})
      : _astrologyService = astrologyService ?? AstrologyService();

  Future<CompatibilityReport> generateCompatibilityReport({
    required String userId,
    required PersonInput personA,
    required PersonInput personB,
  }) async {
    return CompatibilityEngine.calculateCompatibility(
      userId: userId,
      personA: personA,
      personB: personB,
    );
  }
}

/// Provider for compatibility engine
final compatibilityEngineProvider = Provider((ref) {
  return CompatibilityEngine();
});
