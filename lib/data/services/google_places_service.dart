import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';

/// Thrown when a location API returns a non-200 response or the API
/// key is absent / a placeholder (Google Places path only).
class PlacesApiException implements Exception {
  const PlacesApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'PlacesApiException(${statusCode ?? "no-key"}): $message';
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final prediction = json['placePrediction'] as Map<String, dynamic>? ?? {};
    final placeId = prediction['placeId'] as String? ?? '';
    final textObj = prediction['text'] as Map<String, dynamic>? ?? {};
    final description = textObj['text'] as String? ?? '';

    final structuredFormat =
        prediction['structuredFormat'] as Map<String, dynamic>?;
    final mainTextObj =
        structuredFormat?['mainText'] as Map<String, dynamic>?;
    final mainText = mainTextObj?['text'] as String? ?? description;

    final secondaryTextObj =
        structuredFormat?['secondaryText'] as Map<String, dynamic>?;
    final secondaryText = secondaryTextObj?['text'] as String?;

    return PlaceSuggestion(
      placeId: placeId,
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }

  /// Constructs a suggestion from an OpenStreetMap Nominatim result.
  factory PlaceSuggestion.fromNominatim(Map<String, dynamic> json) {
    final displayName = json['display_name'] as String? ?? '';
    final placeId = json['place_id']?.toString() ?? '';

    // Split "City, State, Country" for main/secondary text.
    final parts = displayName.split(', ');
    final mainText = parts.isNotEmpty ? parts.first : displayName;
    final secondaryText = parts.length > 1 ? parts.skip(1).join(', ') : null;

    return PlaceSuggestion(
      placeId: 'osm_$placeId',
      description: displayName,
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }
}

class PlaceDetails {
  const PlaceDetails({
    this.city,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  final String? city;
  final String? country;
  final double latitude;
  final double longitude;

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;

    String? city;
    String? country;

    final addressComponents = json['addressComponents'] as List<dynamic>?;
    if (addressComponents != null) {
      for (final component in addressComponents) {
        final compMap = component as Map<String, dynamic>? ?? {};
        final types = List<String>.from(compMap['types'] ?? []);
        final longText = compMap['longText'] as String?;

        if (types.contains('locality')) {
          city = longText;
        } else if (city == null && types.contains('sublocality')) {
          city = longText;
        } else if (city == null &&
            types.contains('administrative_area_level_2')) {
          city = longText;
        } else if (city == null &&
            types.contains('administrative_area_level_1')) {
          city = longText;
        }

        if (types.contains('country')) {
          country = longText;
        }
      }
    }

    return PlaceDetails(
      city: city,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Constructs place details from an OpenStreetMap Nominatim result.
  factory PlaceDetails.fromNominatim(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0.0;

    final address = json['address'] as Map<String, dynamic>? ?? {};
    final city = address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['county'] as String?;
    final country = address['country'] as String?;

    return PlaceDetails(
      city: city,
      country: country,
      latitude: lat,
      longitude: lon,
    );
  }
}

/// Location service that uses:
/// - OpenStreetMap Nominatim (free, no key) when Google Places key is absent
/// - Google Places API v1 when a valid key is configured
class GooglePlacesService {
  GooglePlacesService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ---------------------------------------------------------------------------
  // Nominatim (free, no key required)
  // ---------------------------------------------------------------------------

  Future<List<PlaceSuggestion>> _nominatimSuggestions(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=5',
    );

    final response = await _client.get(uri, headers: {
      // Nominatim requires a descriptive User-Agent.
      'User-Agent': 'CosmicMatchApp/1.0 (contact@cosmicmatch.app)',
      'Accept-Language': 'en',
    });

    if (response.statusCode != 200) {
      throw PlacesApiException(
        'Nominatim ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PlaceSuggestion.fromNominatim(
            Map<String, dynamic>.from(e as Map)))
        .where((s) => s.placeId.isNotEmpty)
        .take(5)
        .toList();
  }

  Future<PlaceDetails> _nominatimDetails(String placeId) async {
    // placeId is prefixed with "osm_" — strip it to get the numeric OSM id.
    final osmId = placeId.replaceFirst('osm_', '');
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/lookup'
      '?osm_ids=N$osmId,W$osmId,R$osmId'
      '&format=json'
      '&addressdetails=1',
    );

    final response = await _client.get(uri, headers: {
      'User-Agent': 'CosmicMatchApp/1.0 (contact@cosmicmatch.app)',
      'Accept-Language': 'en',
    });

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isNotEmpty) {
        return PlaceDetails.fromNominatim(
            Map<String, dynamic>.from(list.first as Map));
      }
    }

    // Fallback: re-search by the display name stored in the suggestion.
    // This path is hit when the lookup returns an empty list.
    throw PlacesApiException(
      'Nominatim lookup returned no results for $placeId',
    );
  }

  // ---------------------------------------------------------------------------
  // Google Places (used only when a valid key is configured)
  // ---------------------------------------------------------------------------

  Map<String, String> _buildGoogleHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': EnvConfig.googlePlacesApiKey,
    };
    if (EnvConfig.androidSha1Fingerprint.isNotEmpty) {
      headers['X-Android-Package'] = 'com.cosmicmatch.cosmic_match';
      headers['X-Android-Cert'] = EnvConfig.androidSha1Fingerprint;
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Public API — routes to Nominatim or Google Places automatically
  // ---------------------------------------------------------------------------

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) return const [];

    // Prefer Nominatim (free) when Google Places key is absent.
    if (!EnvConfig.hasGooglePlaces) {
      try {
        return await _nominatimSuggestions(query);
      } catch (e, st) {
        debugPrint('GooglePlacesService(Nominatim) autocomplete error: $e\n$st');
        return const [];
      }
    }

    // Google Places path.
    try {
      final response = await _client.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: _buildGoogleHeaders(),
        body: jsonEncode({
          'input': query,
          'includedPrimaryTypes': ['(regions)'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestionsJson = data['suggestions'] as List<dynamic>? ?? [];
        return suggestionsJson
            .map((s) =>
                PlaceSuggestion.fromJson(s as Map<String, dynamic>))
            .where((s) => s.placeId.isNotEmpty)
            .take(5)
            .toList();
      } else {
        throw PlacesApiException(
          '${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, st) {
      debugPrint('GooglePlacesService(Google) autocomplete error: $e\n$st');
      // Degrade to Nominatim on Google failure.
      try {
        return await _nominatimSuggestions(query);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    // OSM-sourced place IDs are prefixed with "osm_".
    if (placeId.startsWith('osm_')) {
      try {
        return await _nominatimDetails(placeId);
      } catch (e, st) {
        debugPrint('GooglePlacesService(Nominatim) details error: $e\n$st');
        rethrow;
      }
    }

    if (!EnvConfig.hasGooglePlaces) {
      throw const PlacesApiException('Google Places API key is not configured');
    }

    try {
      final headers = _buildGoogleHeaders();
      headers['X-Goog-FieldMask'] = 'id,location,addressComponents';

      final response = await _client.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PlaceDetails.fromJson(data);
      } else {
        throw PlacesApiException(
          '${response.statusCode} ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, st) {
      debugPrint('GooglePlacesService(Google) details error: $e\n$st');
      rethrow;
    }
  }
}
