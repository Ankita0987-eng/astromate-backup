import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/birth_chart.dart';
import '../data/models/compatibility_report.dart';
import '../data/models/match_profile.dart';
import '../data/repositories/compatibility_repository.dart';
import '../data/services/astrology_service.dart';

/// State notifier for managing birth chart generation
class BirthChartNotifier extends StateNotifier<AsyncValue<BirthChart?>> {
  final AstrologyService _astrologyService;

  BirthChartNotifier(this._astrologyService)
      : super(const AsyncValue.loading());

  Future<void> generateBirthChart(PersonInput person) async {
    state = const AsyncValue.loading();
    try {
      final kundli = await _astrologyService.generateKundli(
        uid: 'current_user',
        person: person,
      );
      
      // Mock birth chart for now (will integrate with real API)
      final birthChart = BirthChart(
        userId: 'current_user',
        sunSign: kundli.sunSign,
        moonSign: kundli.moonSign,
        ascendant: kundli.ascendant,
        nakshatras: {'Sun': kundli.nakshatra},
        planets: {},
        houses: {},
        aspects: [],
        retrogradeSignatures: {},
        cosmicEnergy: 50.0,
        birthDate: person.birthDate,
        birthTime: person.birthTime,
        birthLocation: person.birthLocation ?? '',
        latitude: person.birthLocationLatitude ?? 0.0,
        longitude: person.birthLocationLongitude ?? 0.0,
        timezone: 5.5,
        rawData: {},
        generatedAt: DateTime.now(),
      );
      
      state = AsyncValue.data(birthChart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final birthChartNotifierProvider =
    StateNotifierProvider.autoDispose<BirthChartNotifier, AsyncValue<BirthChart?>>(
  (ref) {
    final astrologyService = ref.watch(astrologyServiceProvider);
    return BirthChartNotifier(astrologyService);
  },
);

/// Astrology service provider
final astrologyServiceProvider = Provider((ref) => AstrologyService());

/// Compatibility service provider
final compatibilityRepositoryProvider = Provider((ref) => CompatibilityRepository());

/// State for compatibility report generation
class CompatibilityReportNotifier
    extends StateNotifier<AsyncValue<CompatibilityReport?>> {
  final CompatibilityRepository _repository;
  final AstrologyService _astrologyService;

  CompatibilityReportNotifier(this._repository, this._astrologyService)
      : super(const AsyncValue.data(null));

  Future<void> generateReport(PersonInput personA, PersonInput personB) async {
    state = const AsyncValue.loading();
    try {
      final report = await _repository.generateCompatibilityReport(
        userId: 'current_user',
        personA: personA,
        personB: personB,
      );
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final compatibilityReportNotifierProvider = StateNotifierProvider.autoDispose<
    CompatibilityReportNotifier,
    AsyncValue<CompatibilityReport?>>(
  (ref) {
    final repository = ref.watch(compatibilityRepositoryProvider);
    final astrologyService = ref.watch(astrologyServiceProvider);
    return CompatibilityReportNotifier(repository, astrologyService);
  },
);

/// State for swipe matching
class MatchingStateNotifier extends StateNotifier<AsyncValue<List<MatchProfile>>> {
  MatchingStateNotifier() : super(const AsyncValue.loading());

  Future<void> loadMatchProfiles({
    String? genderFilter,
    int? ageMin,
    int? ageMax,
    String? zodiacSign,
  }) async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement actual loading from repository
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final matchingStateNotifierProvider =
    StateNotifierProvider.autoDispose<MatchingStateNotifier, AsyncValue<List<MatchProfile>>>(
  (ref) => MatchingStateNotifier(),
);

/// Loading state management
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Error message provider
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Success message provider
final successMessageProvider = StateProvider<String?>((ref) => null);
