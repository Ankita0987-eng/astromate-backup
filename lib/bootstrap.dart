import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/env_config.dart';
import 'data/services/ads_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';

/// Initializes services then calls [runApp]. Non-critical services must not block UI.
Future<void> bootstrap() async {
  // 1) Environment (assets) — must run before EnvConfig getters / AdsService
  await EnvConfig.load();

  // 2) Local storage
  await LocalStorageService.init();

  // 3) Firebase — required before Auth / Firestore
  await _initializeFirebase();

  // 4) Start UI immediately so we don't hang on native splash
  runApp(const ProviderScope(child: CosmicMatchApp()));

  // 5) Deferred, non-blocking setup (ads, notifications, analytics)
  _initializeDeferredServices();
}

Future<void> _initializeFirebase() async {
  final options = DefaultFirebaseOptions.currentPlatform;

  if (options.appId.contains('YOUR_') || options.apiKey.contains('YOUR_')) {
    throw StateError(
      'Firebase is not configured. Run: flutterfire configure',
    );
  }

  await Firebase.initializeApp(options: options);

  if (kDebugMode) {
    debugPrint('Firebase initialized: ${options.projectId}');
  }

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _initializeDeferredServices() async {
  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e, st) {
    debugPrint('Analytics logAppOpen failed: $e\n$st');
  }

  try {
    await AdsService.instance.initialize();
  } catch (e, st) {
    debugPrint('AdsService init failed: $e\n$st');
  }

  try {
    final notifications = NotificationService();
    await notifications.initialize();
    await notifications.scheduleDailyReminder();
  } catch (e, st) {
    debugPrint('NotificationService init failed: $e\n$st');
  }
}
