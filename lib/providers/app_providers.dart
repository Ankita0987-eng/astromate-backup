import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/compatibility_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/astrology_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/billing_service.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/openai_service.dart';
import '../data/models/user_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
final compatibilityRepositoryProvider =
    Provider<CompatibilityRepository>((ref) => CompatibilityRepository());
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());
final astrologyServiceProvider = Provider<AstrologyService>((ref) {
  return AstrologyService(storage: ref.watch(localStorageProvider));
});
final openAiServiceProvider = Provider<OpenAiService>((ref) => OpenAiService());
final localStorageProvider = Provider<LocalStorageService>((ref) => LocalStorageService());
final billingServiceProvider = Provider<BillingService>((ref) => BillingService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(auth.uid);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  return ThemeModeNotifier(ref.watch(localStorageProvider));
});

class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier(this._storage) : super(_storage.themeMode);

  final LocalStorageService _storage;

  Future<void> setMode(String mode) async {
    state = mode;
    await _storage.setThemeMode(mode);
  }

  void toggle() {
    setMode(state == 'dark' ? 'light' : 'dark');
  }
}

final onboardingCompleteProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref.watch(localStorageProvider));
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._storage)
      : super(_storage.isOnboardingComplete);

  final LocalStorageService _storage;

  Future<void> complete() async {
    await _storage.setOnboardingComplete(true);
    state = true;
  }
}
