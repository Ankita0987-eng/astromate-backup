import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/google_places_service.dart';

final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

final placesAutocompleteProvider =
    StateNotifierProvider<PlacesAutocompleteNotifier, AsyncValue<List<PlaceSuggestion>>>((ref) {
  final service = ref.watch(googlePlacesServiceProvider);
  return PlacesAutocompleteNotifier(service);
});

class PlacesAutocompleteNotifier extends StateNotifier<AsyncValue<List<PlaceSuggestion>>> {
  PlacesAutocompleteNotifier(this._service) : super(const AsyncValue.data([]));

  final GooglePlacesService _service;
  Timer? _debounceTimer;
  String _lastQuery = '';

  void search(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _lastQuery = '';
      state = const AsyncValue.data([]);
      return;
    }

    if (trimmed == _lastQuery) {
      return;
    }

    _lastQuery = trimmed;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      state = const AsyncValue.loading();
      try {
        final suggestions = await _service.getAutocompleteSuggestions(trimmed);
        if (mounted) {
          state = AsyncValue.data(suggestions);
        }
      } catch (e, st) {
        if (mounted) {
          state = AsyncValue.error(e, st);
        }
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    _lastQuery = '';
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
