import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cosmic_match/data/services/google_places_service.dart';
import 'package:cosmic_match/providers/google_places_provider.dart';
import 'package:cosmic_match/core/widgets/google_places_autocomplete.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'GOOGLE_PLACES_API_KEY=mock_api_key\nANDROID_SHA1_FINGERPRINT=mock_fingerprint');
  });

  group('GooglePlacesService Tests', () {
    test('getAutocompleteSuggestions returns list of suggestions on success', () async {
      final mockResponse = {
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'place_123',
              'text': {'text': 'Paris, France'},
              'structuredFormat': {
                'mainText': {'text': 'Paris'},
                'secondaryText': {'text': 'France'},
              },
            }
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/v1/places:autocomplete');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['input'], 'Paris');
        expect(body['includedPrimaryTypes'], ['(regions)']);
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = GooglePlacesService(client: client);
      final suggestions = await service.getAutocompleteSuggestions('Paris');

      expect(suggestions, hasLength(1));
      expect(suggestions.first.placeId, 'place_123');
      expect(suggestions.first.description, 'Paris, France');
      expect(suggestions.first.mainText, 'Paris');
      expect(suggestions.first.secondaryText, 'France');
    });

    test('getPlaceDetails returns place details on success', () async {
      final mockResponse = {
        'location': {
          'latitude': 48.8566,
          'longitude': 2.3522,
        },
        'addressComponents': [
          {
            'longText': 'Paris',
            'types': ['locality', 'political'],
          },
          {
            'longText': 'France',
            'types': ['country', 'political'],
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/v1/places/place_123');
        expect(request.method, 'GET');
        expect(request.headers['X-Goog-FieldMask'], 'id,location,addressComponents');
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = GooglePlacesService(client: client);
      final details = await service.getPlaceDetails('place_123');

      expect(details.latitude, 48.8566);
      expect(details.longitude, 2.3522);
      expect(details.city, 'Paris');
      expect(details.country, 'France');
    });
  });

  group('PlacesAutocompleteNotifier Tests', () {
    test('updates state to data with suggestions after debounce', () async {
      final mockResponse = {
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'place_abc',
              'text': {'text': 'London, UK'},
            }
          }
        ]
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final container = ProviderContainer(
        overrides: [
          googlePlacesServiceProvider.overrideWithValue(GooglePlacesService(client: client)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(placesAutocompleteProvider.notifier);

      // Initially empty
      expect(container.read(placesAutocompleteProvider).value, isEmpty);

      // Search London
      notifier.search('London');

      // Debounce delay is 300ms, let's wait 350ms
      await Future.delayed(const Duration(milliseconds: 350));

      final state = container.read(placesAutocompleteProvider);
      expect(state.value, hasLength(1));
      expect(state.value!.first.placeId, 'place_abc');
      expect(state.value!.first.description, 'London, UK');
    });
  });

  group('GooglePlacesAutocomplete Widget Tests', () {
    testWidgets('renders input field and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooglePlacesAutocomplete(
              onLocationSelected: (name, details) {},
              labelText: 'Location Input',
              hintText: 'Search city...',
            ),
          ),
        ),
      );

      expect(find.text('Location Input'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
