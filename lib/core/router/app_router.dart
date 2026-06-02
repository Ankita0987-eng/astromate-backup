import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai_chat/presentation/ai_chat_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/compatibility/presentation/compatibility_form_screen.dart';
import '../../features/compatibility/presentation/compatibility_result_screen.dart';
import '../../features/compatibility/presentation/compatibility_history_screen.dart';
import '../../features/main_shell/main_shell_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/settings/presentation/legal_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/share/presentation/share_card_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/viral/presentation/viral_features_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/horoscope/presentation/horoscope_screen.dart';
import '../../features/matching/presentation/matching_screen.dart';
import '../../features/messaging/presentation/messages_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../providers/app_providers.dart';
import '../../data/models/compatibility_report.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingDone = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isAuth = loc.startsWith('/auth') || loc == '/onboarding';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;
      if (user == null) {
        if (!onboardingDone && loc != '/onboarding') {
          return '/onboarding';
        }
        if (onboardingDone && !isAuth && !isSplash && loc != '/onboarding') {
          return '/auth/login';
        }
        return null;
      }

      if (isAuth || loc == '/onboarding' || isSplash) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/horoscope',
        builder: (_, __) => const HoroscopeScreen(),
      ),
      GoRoute(
        path: '/matching',
        builder: (_, __) => const MatchingScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (_, __) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (_, state) {
          final matchId = state.pathParameters['matchId'] ?? '';
          final matchName = state.extra as String? ?? 'User';
          return ChatScreen(matchId: matchId, matchName: matchName);
        },
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (_, __) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/compatibility/new',
        builder: (_, __) => const CompatibilityFormScreen(),
      ),
      GoRoute(
        path: '/compatibility/result',
        builder: (_, state) {
          final report = state.extra as CompatibilityReport?;
          if (report == null) {
            return const Scaffold(
              body: Center(child: Text('Report not found')),
            );
          }
          return CompatibilityResultScreen(report: report);
        },
      ),
      GoRoute(
        path: '/compatibility/history',
        builder: (_, __) => const CompatibilityHistoryScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (_, __) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/legal/:type',
        builder: (_, state) {
          final type = state.pathParameters['type'] ?? 'privacy';
          return LegalScreen(type: type);
        },
      ),
      GoRoute(
        path: '/share',
        builder: (_, state) {
          final report = state.extra as CompatibilityReport?;
          return ShareCardScreen(report: report);
        },
      ),
      GoRoute(
        path: '/viral',
        builder: (_, __) => const ViralFeaturesScreen(),
      ),
    ],
  );
});

class GoRouterRefresh extends ChangeNotifier {
  GoRouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingCompleteProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
