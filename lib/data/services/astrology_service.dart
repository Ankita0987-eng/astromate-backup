import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';
import '../../core/utils/zodiac_utils.dart';
import '../models/compatibility_report.dart';
import '../models/daily_horoscope.dart';
import '../models/kundli_data.dart';
import '../models/planet_position.dart';
import 'local_storage_service.dart';

/// Thrown when the AstrologyAPI returns a non-200 response or a network error
/// occurs on endpoints that do not have a mock fallback.
class AstrologyApiException implements Exception {
  const AstrologyApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'AstrologyApiException($statusCode): $message';
}

/// Astrology API with mock fallback when keys are unavailable.
class AstrologyService {
  AstrologyService({http.Client? client, LocalStorageService? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? LocalStorageService();

  final http.Client _client;
  final LocalStorageService _storage;

  // ---------------------------------------------------------------------------
  // Auth / request helpers
  // ---------------------------------------------------------------------------

  String get _basicAuth {
    final credentials =
        '${EnvConfig.astrologyUserId}:${EnvConfig.astrologyApiKey}';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  Map<String, String> get _headers => {
        'Authorization': _basicAuth,
        'Content-Type': 'application/json',
      };

  /// Returns the UTC timezone offset in hours for [p].
  ///
  /// Uses the device's current timezone offset when coordinates are present.
  /// Falls back to 0.0 (UTC) and logs a warning when coordinates are absent.
  double _tzoneFor(PersonInput p) {
    if (p.birthLocationLatitude != null && p.birthLocationLongitude != null) {
      return DateTime.now().timeZoneOffset.inMinutes / 60.0;
    }
    debugPrint(
      'AstrologyService: no coordinates for "${p.name}", defaulting tzone to 0.0',
    );
    return 0.0;
  }

  // ---------------------------------------------------------------------------
  // Cache key helpers
  // ---------------------------------------------------------------------------

  static String _compatCacheKey(PersonInput a, PersonInput b) {
    final dateA = a.birthDate.toIso8601String().substring(0, 10);
    final dateB = b.birthDate.toIso8601String().substring(0, 10);
    return 'compat_${a.name.toLowerCase()}_${dateA}_${b.name.toLowerCase()}_$dateB';
  }

  static String _horoscopeCacheKey(String sign, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'horoscope_${sign.toLowerCase()}_$dateStr';
  }

  static String _planetsCacheKey(String uid, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'planets_${uid}_$dateStr';
  }

  static String _kundliCacheKey(String uid) => 'kundli_$uid';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<CompatibilityReport> generateCompatibility({
    required String userId,
    required String reportId,
    required PersonInput personA,
    required PersonInput personB,
    bool isPremium = false,
  }) async {
    final cacheKey = _compatCacheKey(personA, personB);

    // 1. Cache hit — return immediately without a network call.
    final cached = _storage.getCached<CompatibilityReport>(
      cacheKey,
      (json) => _compatibilityReportFromCache(json as Map<String, dynamic>),
    );
    if (cached != null) return cached;

    // 2. Deterministic generation — no paid API required.
    final report = _generateMockReport(
      userId: userId,
      reportId: reportId,
      personA: personA,
      personB: personB,
      isPremium: isPremium,
    );

    // 3. Cache for 24 hours.
    await _storage.setCached(
      cacheKey,
      _compatibilityReportToCache(report),
      const Duration(hours: 24),
    );
    return report;
  }

  // ---------------------------------------------------------------------------
  // CompatibilityReport cache serialization (JSON-safe — no Firestore types)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _personInputToCache(PersonInput p) => {
        'name': p.name,
        'gender': p.gender,
        'birthDate': p.birthDate.toIso8601String(),
        'birthTime': p.birthTime?.toIso8601String(),
        'birthLocation': p.birthLocation,
        'birthLocationCity': p.birthLocationCity,
        'birthLocationCountry': p.birthLocationCountry,
        'birthLocationLatitude': p.birthLocationLatitude,
        'birthLocationLongitude': p.birthLocationLongitude,
        'zodiacSign': p.zodiacSign,
      };

  static PersonInput _personInputFromCache(Map<String, dynamic> m) =>
      PersonInput(
        name: m['name'] as String? ?? '',
        gender: m['gender'] as String?,
        birthDate: DateTime.parse(m['birthDate'] as String),
        birthTime: m['birthTime'] != null
            ? DateTime.parse(m['birthTime'] as String)
            : null,
        birthLocation: m['birthLocation'] as String?,
        birthLocationCity: m['birthLocationCity'] as String?,
        birthLocationCountry: m['birthLocationCountry'] as String?,
        birthLocationLatitude: (m['birthLocationLatitude'] as num?)?.toDouble(),
        birthLocationLongitude:
            (m['birthLocationLongitude'] as num?)?.toDouble(),
        zodiacSign: m['zodiacSign'] as String? ?? '',
      );

  static Map<String, dynamic> _compatibilityReportToCache(
    CompatibilityReport r,
  ) =>
      {
        'id': r.id,
        'userId': r.userId,
        'personA': _personInputToCache(r.personA),
        'personB': _personInputToCache(r.personB),
        'overallScore': r.overallScore,
        'emotionalScore': r.emotionalScore,
        'communicationScore': r.communicationScore,
        'romanticScore': r.romanticScore,
        'longTermScore': r.longTermScore,
        'soulmatePercentage': r.soulmatePercentage,
        'twinFlameScore': r.twinFlameScore,
        'strengths': r.strengths,
        'weaknesses': r.weaknesses,
        'redFlags': r.redFlags,
        'summary': r.summary,
        'createdAt': r.createdAt.toIso8601String(),
        'isPremiumReport': r.isPremiumReport,
      };

  static CompatibilityReport _compatibilityReportFromCache(
    Map<String, dynamic> m,
  ) =>
      CompatibilityReport(
        id: m['id'] as String? ?? '',
        userId: m['userId'] as String? ?? '',
        personA: _personInputFromCache(
            Map<String, dynamic>.from(m['personA'] as Map)),
        personB: _personInputFromCache(
            Map<String, dynamic>.from(m['personB'] as Map)),
        overallScore: m['overallScore'] as int? ?? 0,
        emotionalScore: m['emotionalScore'] as int? ?? 0,
        communicationScore: m['communicationScore'] as int? ?? 0,
        romanticScore: m['romanticScore'] as int? ?? 0,
        longTermScore: m['longTermScore'] as int? ?? 0,
        soulmatePercentage: m['soulmatePercentage'] as int? ?? 0,
        twinFlameScore: m['twinFlameScore'] as int? ?? 0,
        strengths: List<String>.from(m['strengths'] as List? ?? []),
        weaknesses: List<String>.from(m['weaknesses'] as List? ?? []),
        redFlags: List<String>.from(m['redFlags'] as List? ?? []),
        summary: m['summary'] as String? ?? '',
        createdAt: DateTime.parse(
            m['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        isPremiumReport: m['isPremiumReport'] as bool? ?? false,
      );

  CompatibilityReport _generateMockReport({
    required String userId,
    required String reportId,
    required PersonInput personA,
    required PersonInput personB,
    required bool isPremium,
  }) {
    final seed = ZodiacUtils.compatibilitySeed(
      personA.zodiacSign,
      personB.zodiacSign,
      personA.name,
      personB.name,
    );
    final base = 55 + (seed % 40);
    final elemDiff =
        (ZodiacUtils.elementIndex(personA.zodiacSign) -
                ZodiacUtils.elementIndex(personB.zodiacSign))
            .abs();
    final overall = (base + (4 - elemDiff) * 5).clamp(40, 98);

    return CompatibilityReport(
      id: reportId,
      userId: userId,
      personA: personA,
      personB: personB,
      overallScore: overall,
      emotionalScore: (overall + (seed % 10) - 5).clamp(30, 100),
      communicationScore: (overall + (seed % 15) - 7).clamp(30, 100),
      romanticScore: (overall + (seed % 12)).clamp(30, 100),
      longTermScore: (overall - (seed % 8)).clamp(30, 100),
      soulmatePercentage: (overall * 0.85 + (seed % 10)).round().clamp(30, 99),
      twinFlameScore: (overall * 0.65 + (seed % 15)).round().clamp(20, 95),
      strengths: _mockStrengths(personA.zodiacSign, personB.zodiacSign),
      weaknesses: _mockWeaknesses(personA.zodiacSign, personB.zodiacSign),
      redFlags: overall < 60
          ? [
              'Communication gaps during Mercury retrograde periods',
              'Different emotional pacing may cause friction',
            ]
          : ['Minor ego clashes when both want the spotlight'],
      summary:
          '${personA.name} (${personA.zodiacSign}) and ${personB.name} (${personB.zodiacSign}) share a $overall% cosmic compatibility. '
          'Your ${personA.zodiacSign} energy blends with ${personB.zodiacSign} in ways that ${overall >= 75 ? "amplify passion and growth" : "require patience and understanding"}. '
          'The stars suggest ${overall >= 80 ? "a powerful soulmate potential" : "a meaningful connection worth exploring"}.',
      createdAt: DateTime.now(),
      isPremiumReport: isPremium,
    );
  }

  List<String> _mockStrengths(String s1, String s2) => [
        '${s1} brings passion while ${s2} adds depth',
        'Strong intuitive connection between your signs',
        'Complementary communication styles when aligned',
        'Shared growth potential in love and friendship',
      ];

  List<String> _mockWeaknesses(String s1, String s2) => [
        'Different approaches to emotional expression',
        '${s1} and ${s2} may clash on decision timing',
        'Need clear boundaries around personal space',
      ];

  Future<DailyHoroscope> getDailyHoroscope(String zodiacSign) async {
    final now = DateTime.now();
    final cacheKey = _horoscopeCacheKey(zodiacSign, now);

    // 1. Cache hit.
    final cached = _storage.getCached<DailyHoroscope>(
      cacheKey,
      (json) {
        final m = json as Map<String, dynamic>;
        return DailyHoroscope(
          zodiacSign: m['zodiacSign'] as String,
          date: m['date'] as String,
          loveHoroscope: m['loveHoroscope'] as String,
          careerHoroscope: m['careerHoroscope'] as String,
          moodInsight: m['moodInsight'] as String,
          loveEnergy: m['loveEnergy'] as int,
          cosmicEnergy: m['cosmicEnergy'] as String,
          luckyNumber: m['luckyNumber'] as int,
          luckyColor: m['luckyColor'] as String,
        );
      },
    );
    if (cached != null) return cached;

    // 2. Deterministic generation — no paid API required.
    final horoscope = _generateMockHoroscope(zodiacSign, now);

    // 3. Cache until midnight.
    await _storage.setCached(
      cacheKey,
      {
        'zodiacSign': horoscope.zodiacSign,
        'date': horoscope.date,
        'loveHoroscope': horoscope.loveHoroscope,
        'careerHoroscope': horoscope.careerHoroscope,
        'moodInsight': horoscope.moodInsight,
        'loveEnergy': horoscope.loveEnergy,
        'cosmicEnergy': horoscope.cosmicEnergy,
        'luckyNumber': horoscope.luckyNumber,
        'luckyColor': horoscope.luckyColor,
      },
      LocalStorageService.untilMidnight(),
    );
    return horoscope;
  }

  DailyHoroscope _generateMockHoroscope(String zodiacSign, DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final seed = zodiacSign.codeUnits.fold(0, (a, b) => a + b) + date.day;

    return DailyHoroscope(
      zodiacSign: zodiacSign,
      date: dateKey,
      loveHoroscope:
          'Today Venus aligns with your $zodiacSign energy. Open your heart to unexpected connections. '
          'A conversation could spark something magical.',
      careerHoroscope:
          'Mercury supports clarity for $zodiacSign. Focus on one priority project. '
          'Your intuition guides a smart professional move.',
      moodInsight: seed % 2 == 0
          ? 'Reflective and dreamy — perfect for journaling.'
          : 'Bold and magnetic — others notice your cosmic glow.',
      loveEnergy: 60 + (seed % 35),
      cosmicEnergy: ['Transformative', 'Harmonious', 'Electric', 'Mystical'][seed % 4],
      luckyNumber: (seed % 9) + 1,
      luckyColor: ['Purple', 'Rose Gold', 'Midnight Blue', 'Silver'][seed % 4],
    );
  }

  /// Returns deterministic planetary positions derived from [person]'s birth data.
  ///
  /// No network call is made. Results are cached for 24 hours.
  Future<List<PlanetPosition>> getPlanetaryPositions({
    required String uid,
    required PersonInput person,
  }) async {
    final now = DateTime.now();
    final cacheKey = _planetsCacheKey(uid, now);

    final cached = _storage.getCached<List<PlanetPosition>>(
      cacheKey,
      (json) => (json as List)
          .map((e) => PlanetPosition.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
    if (cached != null) return cached;

    final planets = _generatePlanetPositions(person, now);
    await _storage.setCached(
      cacheKey,
      planets.map((p) => p.toJson()).toList(),
      const Duration(hours: 24),
    );
    return planets;
  }

  /// Generates deterministic planetary positions from birth data + today's date.
  List<PlanetPosition> _generatePlanetPositions(
      PersonInput person, DateTime now) {
    final seed =
        person.birthDate.millisecondsSinceEpoch + now.day + now.month;
    const planetNames = [
      'Sun', 'Moon', 'Mercury', 'Venus', 'Mars',
      'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto',
    ];
    const signs = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
    ];

    return List.generate(planetNames.length, (i) {
      final s = (seed + i * 137) % signs.length;
      final degree = ((seed + i * 29) % 3000) / 100.0;
      final isRetrograde = (seed + i) % 7 == 0;
      return PlanetPosition(
        planet: planetNames[i],
        sign: signs[s],
        degree: degree,
        isRetrograde: isRetrograde,
      );
    });
  }

  /// Returns a deterministic Kundli derived from [person]'s birth data.
  ///
  /// No network call is made. Results are cached for 7 days.
  Future<KundliData> generateKundli({
    required String uid,
    required PersonInput person,
  }) async {
    final cacheKey = _kundliCacheKey(uid);

    final cached = _storage.getCached<KundliData>(
      cacheKey,
      (json) =>
          KundliData.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (cached != null) return cached;

    final kundli = _generateKundliData(person);
    await _storage.setCached(cacheKey, kundli.toJson(), const Duration(days: 7));
    return kundli;
  }

  /// Derives Kundli fields deterministically from birth date and zodiac sign.
  KundliData _generateKundliData(PersonInput person) {
    const signs = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
    ];
    const nakshatras = [
      'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
      'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni',
      'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha',
      'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha',
      'Shravana', 'Dhanishtha', 'Shatabhisha', 'Purva Bhadrapada',
      'Uttara Bhadrapada', 'Revati',
    ];

    final seed = person.birthDate.millisecondsSinceEpoch;
    final sunSign = person.zodiacSign;
    final moonSign = signs[(seed ~/ 1000000) % signs.length];
    final ascendant = signs[(seed ~/ 100000) % signs.length];
    final nakshatra = nakshatras[(seed ~/ 10000) % nakshatras.length];

    return KundliData(
      sunSign: sunSign,
      moonSign: moonSign,
      ascendant: ascendant,
      nakshatra: nakshatra,
    );
  }

  String celebrityMatch(String userSign) {
    const matches = {
      'Aries': 'Lady Gaga',
      'Taurus': 'Adele',
      'Gemini': 'Kanye West',
      'Cancer': 'Selena Gomez',
      'Leo': 'Jennifer Lopez',
      'Virgo': 'Beyoncé',
      'Libra': 'Will Smith',
      'Scorpio': 'Drake',
      'Sagittarius': 'Taylor Swift',
      'Capricorn': 'Michelle Obama',
      'Aquarius': 'Oprah Winfrey',
      'Pisces': 'Rihanna',
    };
    return matches[userSign] ?? 'Zendaya';
  }

  List<MapEntry<String, int>> bestZodiacMatches(String sign) {
    final all = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
    ];
    return all
        .where((s) => s != sign)
        .map((s) => MapEntry(
              s,
              55 +
                  (ZodiacUtils.compatibilitySeed(sign, s, '', '') % 40),
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
