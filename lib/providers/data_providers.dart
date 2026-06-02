import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/astrology_repository.dart';
import '../data/repositories/horoscope_repository.dart';
import '../data/repositories/matching_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/messaging_repository.dart';
import '../data/repositories/ai_chat_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/birth_chart.dart';
import '../data/models/horoscope_data.dart';
import '../data/models/match_profile.dart';
import '../data/models/subscription_plan.dart';
import '../data/models/user_profile.dart';

// ============== REPOSITORY PROVIDERS ==============

final astrologyRepositoryProvider = Provider((ref) => AstrologyRepository());

final horoscopeRepositoryProvider = Provider((ref) => HoroscopeRepository());

final matchingRepositoryProvider = Provider((ref) => MatchingRepository());

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository());

final messagingRepositoryProvider = Provider((ref) => MessagingRepository());

final aiChatRepositoryProvider = Provider((ref) => AIChatRepository());

final userRepositoryProvider = Provider((ref) => UserRepository());

// ============== BIRTH CHART PROVIDERS ==============

final birthChartProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getBirthChart();
});

final birthChartStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.watchBirthChart();
});

final cosmicEnergyProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.calculateCosmicEnergy();
});

final planetPositionsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getPlanetPositions();
});

final housesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getHouses();
});

final aspectsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getAspects();
});

// ============== HOROSCOPE PROVIDERS ==============

final dailyHoroscopeProvider = FutureProvider.autoDispose
    .family<HoroscopeData?, String>((ref, zodiacSign) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getDailyHoroscope(zodiacSign);
});

final weeklyHoroscopeProvider = FutureProvider.autoDispose
    .family<HoroscopeData?, String>((ref, zodiacSign) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getWeeklyHoroscope(zodiacSign);
});

final monthlyHoroscopeProvider = FutureProvider.autoDispose
    .family<HoroscopeData?, String>((ref, zodiacSign) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getMonthlyHoroscope(zodiacSign);
});

final yearlyHoroscopeProvider = FutureProvider.autoDispose
    .family<HoroscopeData?, String>((ref, zodiacSign) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getYearlyHoroscope(zodiacSign);
});

// ============== MATCHING PROVIDERS ==============

final matchProfilesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(matchingRepositoryProvider);
  return repo.getMatchProfiles();
});

final matchesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(matchingRepositoryProvider);
  return repo.getMatches();
});

final matchesStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(matchingRepositoryProvider);
  return repo.watchMatches();
});

// ============== SUBSCRIPTION PROVIDERS ==============

final subscriptionPlansProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getAvailablePlans();
});

final subscriptionPlansStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchAvailablePlans();
});

final currentSubscriptionProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getCurrentSubscription();
});

final currentSubscriptionStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.watchSubscription();
});

final hasPremiumAccessProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.hasPremiumAccess();
});

final remainingUsageProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getRemainingUsage();
});

final billingHistoryProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getBillingHistory();
});

// ============== MESSAGING PROVIDERS ==============

final chatThreadsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getChatThreads();
});

final chatThreadsStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.watchChatThreads();
});

final notificationsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getNotifications();
});

final notificationsStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.watchNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getUnreadCount();
});

// ============== AI CHAT PROVIDERS ==============

final aiChatHistoryProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.getChatHistory();
});

final aiChatStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.watchChatHistory();
});

final aiUsageStatsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.getUsageStats();
});

final aiUsageStatsStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.watchUsageStats();
});

final canUseAIChatProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.canUseAIChat();
});

final remainingAIMessagesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.getRemainingMessages();
});

// ============== USER PROFILE PROVIDERS ==============

final currentUserProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchCurrentUser();
});

final userProfileProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getCurrentUser();
});

final otherUserProfileProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfile(userId);
});

final profileCompleteProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.isProfileComplete ?? false;
});

// ============== ADDITIONAL PROVIDERS ==============

final currentUserBirthChartProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getBirthChart();
});

final potentialMatchesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(matchingRepositoryProvider);
  return repo.getMatchProfiles();
});

final chatMessagesProvider = FutureProvider.autoDispose.family<List, String>((ref, otherUserId) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getMessages(otherUserId);
});

final chatMessagesStreamProvider = StreamProvider.autoDispose.family((ref, otherUserId) {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.watchMessages(otherUserId);
});
