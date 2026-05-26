import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cosmic_match/app.dart';
import 'package:cosmic_match/data/services/local_storage_service.dart';
import 'package:cosmic_match/providers/app_providers.dart';

class MockLocalStorageService extends LocalStorageService {
  @override
  bool get isOnboardingComplete => false;

  @override
  Future<void> setOnboardingComplete(bool value) async {}

  @override
  String get themeMode => 'dark';

  @override
  Future<void> setThemeMode(String mode) async {}
}

void main() {
  testWidgets('Cosmic Match app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(MockLocalStorageService()),
        ],
        child: const CosmicMatchApp(),
      ),
    );
    expect(find.text('Cosmic Match'), findsNothing);
  });
}
