import '../../data/models/compatibility_report.dart';
import '../../data/models/birth_chart.dart';

/// Compatibility engine for calculating relationship scores
class CompatibilityEngine {
  /// Zodiac compatibility matrix (144 pairs)
  static const Map<String, Map<String, int>> compatibilityMatrix = {
    'Aries': {
      'Aries': 75,
      'Taurus': 45,
      'Gemini': 80,
      'Cancer': 40,
      'Leo': 90,
      'Virgo': 35,
      'Libra': 70,
      'Scorpio': 50,
      'Sagittarius': 85,
      'Capricorn': 40,
      'Aquarius': 75,
      'Pisces': 35,
    },
    'Taurus': {
      'Aries': 45,
      'Taurus': 85,
      'Gemini': 40,
      'Cancer': 85,
      'Leo': 45,
      'Virgo': 90,
      'Libra': 50,
      'Scorpio': 75,
      'Sagittarius': 40,
      'Capricorn': 85,
      'Aquarius': 30,
      'Pisces': 80,
    },
    'Gemini': {
      'Aries': 80,
      'Taurus': 40,
      'Gemini': 80,
      'Cancer': 45,
      'Leo': 70,
      'Virgo': 85,
      'Libra': 90,
      'Scorpio': 40,
      'Sagittarius': 75,
      'Capricorn': 50,
      'Aquarius': 85,
      'Pisces': 45,
    },
    'Cancer': {
      'Aries': 40,
      'Taurus': 85,
      'Gemini': 45,
      'Cancer': 80,
      'Leo': 50,
      'Virgo': 85,
      'Libra': 40,
      'Scorpio': 90,
      'Sagittarius': 35,
      'Capricorn': 80,
      'Aquarius': 40,
      'Pisces': 85,
    },
    'Leo': {
      'Aries': 90,
      'Taurus': 45,
      'Gemini': 70,
      'Cancer': 50,
      'Leo': 85,
      'Virgo': 40,
      'Libra': 80,
      'Scorpio': 45,
      'Sagittarius': 90,
      'Capricorn': 45,
      'Aquarius': 50,
      'Pisces': 40,
    },
    'Virgo': {
      'Aries': 35,
      'Taurus': 90,
      'Gemini': 85,
      'Cancer': 85,
      'Leo': 40,
      'Virgo': 80,
      'Libra': 45,
      'Scorpio': 85,
      'Sagittarius': 35,
      'Capricorn': 90,
      'Aquarius': 40,
      'Pisces': 75,
    },
    'Libra': {
      'Aries': 70,
      'Taurus': 50,
      'Gemini': 90,
      'Cancer': 40,
      'Leo': 80,
      'Virgo': 45,
      'Libra': 85,
      'Scorpio': 50,
      'Sagittarius': 80,
      'Capricorn': 55,
      'Aquarius': 85,
      'Pisces': 60,
    },
    'Scorpio': {
      'Aries': 50,
      'Taurus': 75,
      'Gemini': 40,
      'Cancer': 90,
      'Leo': 45,
      'Virgo': 85,
      'Libra': 50,
      'Scorpio': 85,
      'Sagittarius': 55,
      'Capricorn': 85,
      'Aquarius': 35,
      'Pisces': 85,
    },
    'Sagittarius': {
      'Aries': 85,
      'Taurus': 40,
      'Gemini': 75,
      'Cancer': 35,
      'Leo': 90,
      'Virgo': 35,
      'Libra': 80,
      'Scorpio': 55,
      'Sagittarius': 80,
      'Capricorn': 40,
      'Aquarius': 85,
      'Pisces': 40,
    },
    'Capricorn': {
      'Aries': 40,
      'Taurus': 85,
      'Gemini': 50,
      'Cancer': 80,
      'Leo': 45,
      'Virgo': 90,
      'Libra': 55,
      'Scorpio': 85,
      'Sagittarius': 40,
      'Capricorn': 85,
      'Aquarius': 45,
      'Pisces': 80,
    },
    'Aquarius': {
      'Aries': 75,
      'Taurus': 30,
      'Gemini': 85,
      'Cancer': 40,
      'Leo': 50,
      'Virgo': 40,
      'Libra': 85,
      'Scorpio': 35,
      'Sagittarius': 85,
      'Capricorn': 45,
      'Aquarius': 80,
      'Pisces': 50,
    },
    'Pisces': {
      'Aries': 35,
      'Taurus': 80,
      'Gemini': 45,
      'Cancer': 85,
      'Leo': 40,
      'Virgo': 75,
      'Libra': 60,
      'Scorpio': 85,
      'Sagittarius': 40,
      'Capricorn': 80,
      'Aquarius': 50,
      'Pisces': 80,
    },
  };

  /// Calculate detailed compatibility between two birth charts
  static int calculateCompatibility(
    BirthChart chart1,
    BirthChart chart2,
  ) {
    // Calculate compatibility from zodiac signs
    int sunCompat = compatibilityMatrix[chart1.sunSign]?[chart2.sunSign] ?? 50;
    int moonCompat = compatibilityMatrix[chart1.moonSign]?[chart2.moonSign] ?? 50;
    int venusCompat = compatibilityMatrix[chart1.venusSign]?[chart2.venusSign] ?? 50;

    // Weighted average: 50% sun, 30% moon, 20% venus
    return ((sunCompat * 0.5) + (moonCompat * 0.3) + (venusCompat * 0.2)).toInt();
  }

  /// Calculate compatibility based on zodiac signs only
  static int calculateZodiacCompatibility(String sign1, String sign2) {
    return compatibilityMatrix[sign1]?[sign2] ?? 50;
  }

  /// Get emotional compatibility
  static int getEmotionalCompatibility(BirthChart chart1, BirthChart chart2) {
    // Moon sign represents emotions
    int moonCompat = compatibilityMatrix[chart1.moonSign]?[chart2.moonSign] ?? 50;
    return moonCompat;
  }

  /// Get romantic compatibility
  static int getRomanticCompatibility(BirthChart chart1, BirthChart chart2) {
    // Venus sign represents romance and love, fall back to sun sign
    final venus1 = chart1.venusSign ?? chart1.sunSign;
    final venus2 = chart2.venusSign ?? chart2.sunSign;
    return compatibilityMatrix[venus1]?[venus2] ?? 50;
  }

  /// Get communication compatibility
  static int getCommunicationCompatibility(BirthChart chart1, BirthChart chart2) {
    // Mercury sign represents communication, fall back to sun sign
    final mercury1 = chart1.mercurySign ?? chart1.sunSign;
    final mercury2 = chart2.mercurySign ?? chart2.sunSign;
    return compatibilityMatrix[mercury1]?[mercury2] ?? 50;
  }

  /// Determine relationship strengths based on compatibility
  static List<String> determineStrengths(int overall, int emotional, int romantic) {
    final strengths = <String>[];

    if (overall >= 75) {
      strengths.add('Excellent overall compatibility');
    }

    if (emotional >= 80) {
      strengths.add('Deep emotional connection');
    }

    if (romantic >= 80) {
      strengths.add('Strong romantic attraction');
    }

    if (overall >= 70 && emotional >= 70) {
      strengths.add('Natural understanding');
    }

    if (strengths.isEmpty) {
      strengths.add('Growing potential in the relationship');
    }

    return strengths;
  }

  /// Determine relationship weaknesses
  static List<String> determineWeaknesses(int overall, int emotional, int romantic) {
    final weaknesses = <String>[];

    if (overall < 50) {
      weaknesses.add('Significant compatibility challenges');
    }

    if (emotional < 50) {
      weaknesses.add('Emotional distance');
    }

    if (romantic < 50) {
      weaknesses.add('Limited romantic alignment');
    }

    if (overall < 60 && romantic < 60) {
      weaknesses.add('Different love languages');
    }

    return weaknesses;
  }

  /// Determine red flags in the relationship
  static List<String> determineRedFlags(BirthChart chart1, BirthChart chart2) {
    final redFlags = <String>[];

    // Check for challenging aspects
    final compat = calculateCompatibility(chart1, chart2);

    if (compat < 40) {
      redFlags.add('Fundamental value differences');
    }

    if (chart1.sunSign == 'Scorpio' && chart2.sunSign == 'Gemini') {
      redFlags.add('Different life paces');
    }

    if (chart1.moonSign == 'Capricorn' && chart2.moonSign == 'Pisces') {
      redFlags.add('Emotional expression differences');
    }

    return redFlags;
  }

  /// Generate detailed compatibility report
  static CompatibilityReport generateReport(
    BirthChart chart1,
    BirthChart chart2,
    String person1Name,
    String person2Name,
    String userId,
  ) {
    final overall = calculateCompatibility(chart1, chart2);
    final emotional = getEmotionalCompatibility(chart1, chart2);
    final romantic = getRomanticCompatibility(chart1, chart2);
    final communication = getCommunicationCompatibility(chart1, chart2);

    final soulmatePercentage = ((emotional + romantic) ~/ 2).clamp(0, 100);
    final twinFlameScore = ((overall + communication) ~/ 2).clamp(0, 100);

    final strengths = determineStrengths(overall, emotional, romantic);
    final weaknesses = determineWeaknesses(overall, emotional, romantic);
    final redFlags = determineRedFlags(chart1, chart2);
    final interpretation = _generateInterpretation(overall);

    return CompatibilityReport(
      id: '${chart1.userId}_${chart2.userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      personA: PersonInput(
        name: person1Name,
        birthDate: chart1.birthDate,
        zodiacSign: chart1.sunSign,
      ),
      personB: PersonInput(
        name: person2Name,
        birthDate: chart2.birthDate,
        zodiacSign: chart2.sunSign,
      ),
      overallScore: overall,
      emotionalScore: emotional,
      communicationScore: communication,
      romanticScore: romantic,
      longTermScore: communication,
      soulmatePercentage: soulmatePercentage,
      twinFlameScore: twinFlameScore,
      strengths: strengths,
      weaknesses: weaknesses,
      redFlags: redFlags,
      summary: interpretation,
      createdAt: DateTime.now(),
    );
  }

  /// Generate human-readable interpretation
  static String _generateInterpretation(int score) {
    if (score >= 85) {
      return 'Excellent match with strong potential for a lasting, fulfilling relationship.';
    } else if (score >= 70) {
      return 'Good compatibility with solid foundation. Both partners can work towards a strong bond.';
    } else if (score >= 55) {
      return 'Moderate compatibility. Differences exist but can be bridged with effort and understanding.';
    } else if (score >= 40) {
      return 'Challenging compatibility. Significant differences require conscious effort to harmonize.';
    } else {
      return 'Very low compatibility. Fundamental differences may make this relationship difficult.';
    }
  }
}
