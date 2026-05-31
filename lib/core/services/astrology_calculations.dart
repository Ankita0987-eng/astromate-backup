import 'package:flutter/foundation.dart';
import '../../data/models/birth_chart.dart';
import '../../data/models/planet_position.dart';

/// Advanced astrology calculations and interpretations.
class AstrologyCalculations {
  /// Zodiac signs in order
  static const List<String> zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  /// Calculate sun sign from birth date
  static String calculateSunSign(DateTime birthDate) {
    const dayRanges = [
      (3, 20, 'Aries'),
      (4, 19, 'Taurus'),
      (5, 20, 'Gemini'),
      (6, 20, 'Cancer'),
      (7, 22, 'Leo'),
      (8, 22, 'Virgo'),
      (9, 22, 'Libra'),
      (10, 22, 'Scorpio'),
      (11, 21, 'Sagittarius'),
      (12, 21, 'Capricorn'),
      (1, 19, 'Aquarius'),
      (2, 18, 'Pisces'),
    ];

    final month = birthDate.month;
    final day = birthDate.day;

    for (var (m, d, sign) in dayRanges) {
      if ((month == m && day >= d) || (month == (m % 12) + 1 && day < d)) {
        return sign;
      }
    }

    return 'Pisces'; // Default
  }

  /// Calculate lunar days (tithi)
  static String calculateTithi(DateTime date) {
    final dayOfMonth = date.day;
    final tithi = ((dayOfMonth + 12) % 30);

    const tithis = [
      'Amavasya (New Moon)',
      'Pratipada',
      'Dwitiya',
      'Tritiya',
      'Chaturthi',
      'Panchami',
      'Shashthi',
      'Saptami',
      'Ashtami',
      'Navami',
      'Dashami',
      'Ekadashi',
      'Dwadashi',
      'Trayodashi',
      'Chaturdashi',
      'Purnima (Full Moon)',
      'Pratipada',
      'Dwitiya',
      'Tritiya',
      'Chaturthi',
      'Panchami',
      'Shashthi',
      'Saptami',
      'Ashtami',
      'Navami',
      'Dashami',
      'Ekadashi',
      'Dwadashi',
      'Trayodashi',
      'Chaturdashi',
    ];

    return tithis[tithi.clamp(0, tithis.length - 1)];
  }

  /// Calculate aspect between two planets
  static String calculateAspect(double angle) {
    angle = angle % 360;
    const tolerance = 8.0;

    if ((angle - 0).abs() <= tolerance || (angle - 360).abs() <= tolerance) {
      return 'Conjunction (0°)';
    } else if ((angle - 60).abs() <= tolerance) {
      return 'Sextile (60°)';
    } else if ((angle - 90).abs() <= tolerance) {
      return 'Square (90°)';
    } else if ((angle - 120).abs() <= tolerance) {
      return 'Trine (120°)';
    } else if ((angle - 180).abs() <= tolerance) {
      return 'Opposition (180°)';
    }

    return 'No major aspect';
  }

  /// Get aspect quality (harmonious or challenging)
  static String getAspectQuality(String aspect) {
    if (aspect.contains('Sextile') || aspect.contains('Trine')) {
      return 'Harmonious';
    } else if (aspect.contains('Square') || aspect.contains('Opposition')) {
      return 'Challenging';
    } else if (aspect.contains('Conjunction')) {
      return 'Neutral';
    }
    return 'Neutral';
  }

  /// Calculate retrograde effect
  static String getRetrogradeMeaning(String planet) {
    const meanings = {
      'Mercury':
          'Communication challenges, rethinking plans, internal reflection',
      'Venus':
          'Relationship review, artistic reassessment, relationship delays',
      'Mars': 'Action delays, frustration, need for internal strength',
      'Jupiter': 'Expansion challenges, inward growth, philosophical review',
      'Saturn':
          'Karmic lessons, responsibility review, structural changes',
      'Uranus': 'Sudden changes review, liberation reassessment',
      'Neptune':
          'Illusion clarity, spiritual review, boundary clarification',
      'Pluto': 'Power dynamics review, deep transformation, rebirth',
    };

    return meanings[planet] ?? 'Internalization of planetary energy';
  }

  /// Get house significance
  static String getHouseSignificance(int house) {
    const meanings = {
      1: 'Personality, appearance, self-image, new beginnings',
      2: 'Finances, possessions, values, self-esteem',
      3: 'Communication, learning, short trips, siblings',
      4: 'Home, family, private life, real estate, endings',
      5: 'Creativity, romance, children, entertainment, speculation',
      6: 'Work, health, daily routines, service, pets',
      7: 'Partnerships, marriage, contracts, public relations',
      8: 'Sexuality, finances, psychology, transformation, death/rebirth',
      9: 'Higher learning, travel, philosophy, spirituality, publishing',
      10: 'Career, public image, authority, ambition, reputation',
      11: 'Friendships, groups, technology, hopes, humanitarian causes',
      12: 'Spirituality, karma, subconscious, solitude, hidden matters',
    };

    return meanings[house] ?? 'Unknown';
  }

  /// Get planet interpretation
  static String getPlanetInterpretation(String planet, String sign) {
    // Simplified interpretations
    const interpretations = {
      'Sun': 'Core identity, life purpose, creative expression',
      'Moon': 'Emotions, inner world, instinctive responses',
      'Mercury': 'Communication, thinking, learning, writing',
      'Venus': 'Love, beauty, values, social harmony',
      'Mars': 'Action, passion, aggression, motivation',
      'Jupiter': 'Expansion, luck, wisdom, generosity',
      'Saturn': 'Restriction, discipline, lessons, responsibility',
      'Uranus': 'Innovation, rebellion, change, technology',
      'Neptune': 'Spirituality, illusions, dreams, intuition',
      'Pluto': 'Transformation, power, rebirth, shadow self',
      'Rahu': 'Obsession, ambition, materiality, worldly desires',
      'Ketu': 'Spirituality, detachment, past karma, wisdom',
    };

    return '\${interpretations[planet] ?? planet} in \$sign';
  }

  /// Calculate compatibility score between two charts
  static int calculateCompatibilityScore(
    BirthChart chart1,
    BirthChart chart2,
  ) {
    int score = 50; // Base score

    // Sun sign compatibility
    final sunCompat = _getZodiacCompatibility(chart1.sunSign, chart2.sunSign);
    score += sunCompat;

    // Moon sign compatibility (emotional)
    final moonCompat = _getZodiacCompatibility(chart1.moonSign, chart2.moonSign);
    score += (moonCompat * 0.7).toInt();

    // Venus (love) compatibility
    final venusCompat = _getZodiacCompatibility(chart1.sunSign, chart2.sunSign);
    score += (venusCompat * 0.6).toInt();

    // Aspect compatibility
    final aspectScore = _calculateAspectCompatibility(chart1.aspects, chart2.aspects);
    score += (aspectScore * 0.5).toInt();

    // Normalize to 0-100
    return score.clamp(0, 100);
  }

  /// Check if date is during retrograde
  static bool isRetrograde(String planet, DateTime date) {
    // Simplified retrograde calculations
    final month = date.month;
    final retrogradeMonths = {
      'Mercury': [3, 7, 11],
      'Venus': [6, 12],
      'Mars': [10],
      'Jupiter': [9],
      'Saturn': [5],
    };

    return retrogradeMonths[planet]?.contains(month) ?? false;
  }

  /// Calculate cosmic energy based on planetary positions
  static double calculateCosmicEnergy(List<AspectData> aspects) {
    double energy = 50.0;

    for (final aspect in aspects) {
      if (aspect.type == 'trine' || aspect.type == 'sextile') {
        energy += 8;
      } else if (aspect.type == 'square' || aspect.type == 'opposition') {
        energy -= 5;
      } else if (aspect.type == 'conjunction') {
        energy += 3;
      }
    }

    return energy.clamp(0.0, 100.0);
  }

  // ============== PRIVATE HELPERS ==============

  static int _getZodiacCompatibility(String sign1, String sign2) {
    const compatibility = {
      'Aries-Aries': 80,
      'Aries-Taurus': 65,
      'Aries-Gemini': 90,
      'Aries-Cancer': 45,
      'Aries-Leo': 95,
      'Aries-Virgo': 50,
      'Aries-Libra': 75,
      'Aries-Scorpio': 60,
      'Aries-Sagittarius': 95,
      'Aries-Capricorn': 55,
      'Aries-Aquarius': 85,
      'Aries-Pisces': 50,
      'Taurus-Taurus': 85,
      'Taurus-Gemini': 60,
      'Taurus-Cancer': 85,
      'Taurus-Leo': 55,
      'Taurus-Virgo': 90,
      'Taurus-Libra': 60,
      'Taurus-Scorpio': 75,
      'Taurus-Sagittarius': 40,
      'Taurus-Capricorn': 95,
      'Taurus-Aquarius': 45,
      'Taurus-Pisces': 80,
      'Gemini-Gemini': 90,
      'Gemini-Cancer': 60,
      'Gemini-Leo': 80,
      'Gemini-Virgo': 85,
      'Gemini-Libra': 95,
      'Gemini-Scorpio': 60,
      'Gemini-Sagittarius': 75,
      'Gemini-Capricorn': 50,
      'Gemini-Aquarius': 95,
      'Gemini-Pisces': 65,
      'Cancer-Cancer': 85,
      'Cancer-Leo': 70,
      'Cancer-Virgo': 80,
      'Cancer-Libra': 60,
      'Cancer-Scorpio': 95,
      'Cancer-Sagittarius': 55,
      'Cancer-Capricorn': 70,
      'Cancer-Aquarius': 45,
      'Cancer-Pisces': 95,
      'Leo-Leo': 90,
      'Leo-Virgo': 60,
      'Leo-Libra': 85,
      'Leo-Scorpio': 65,
      'Leo-Sagittarius': 95,
      'Leo-Capricorn': 55,
      'Leo-Aquarius': 70,
      'Leo-Pisces': 60,
      'Virgo-Virgo': 85,
      'Virgo-Libra': 70,
      'Virgo-Scorpio': 85,
      'Virgo-Sagittarius': 50,
      'Virgo-Capricorn': 95,
      'Virgo-Aquarius': 60,
      'Virgo-Pisces': 70,
      'Libra-Libra': 90,
      'Libra-Scorpio': 70,
      'Libra-Sagittarius': 85,
      'Libra-Capricorn': 65,
      'Libra-Aquarius': 95,
      'Libra-Pisces': 75,
      'Scorpio-Scorpio': 85,
      'Scorpio-Sagittarius': 65,
      'Scorpio-Capricorn': 90,
      'Scorpio-Aquarius': 55,
      'Scorpio-Pisces': 95,
      'Sagittarius-Sagittarius': 90,
      'Sagittarius-Capricorn': 60,
      'Sagittarius-Aquarius': 85,
      'Sagittarius-Pisces': 65,
      'Capricorn-Capricorn': 85,
      'Capricorn-Aquarius': 65,
      'Capricorn-Pisces': 70,
      'Aquarius-Aquarius': 90,
      'Aquarius-Pisces': 65,
      'Pisces-Pisces': 90,
    };

    final key1 = '\$sign1-\$sign2';
    final key2 = '\$sign2-\$sign1';

    return compatibility[key1] ?? compatibility[key2] ?? 65;
  }

  static int _calculateAspectCompatibility(
    List<AspectData> aspects1,
    List<AspectData> aspects2,
  ) {
    int score = 0;

    for (final a1 in aspects1) {
      for (final a2 in aspects2) {
        if (a1.type == a2.type) {
          if (a1.type == 'trine' || a1.type == 'sextile') {
            score += 10;
          } else if (a1.type == 'square' || a1.type == 'opposition') {
            score -= 5;
          }
        }
      }
    }

    return score;
  }
}
