class AppConstants {
  AppConstants._();

  static const String appName = 'Cosmic Match';
  static const String appTagline = 'Find Your Cosmic Connection';

  // Free tier limits
  static const int freeCompatibilityChecksPerDay = 3;
  static const int freeAiMessagesPerDay = 10;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String compatibilityReportsCollection = 'compatibility_reports';
  static const String aiChatsCollection = 'ai_chats';
  static const String subscriptionsCollection = 'subscriptions';
  static const String dailyHoroscopesCollection = 'daily_horoscopes';

  // Hive boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String onboardingBox = 'onboarding';

  // Hive keys
  static const String themeModeKey = 'theme_mode';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String dailyUsageKey = 'daily_usage';
  static const String lastUsageDateKey = 'last_usage_date';

  static const List<String> zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  static const List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  static const List<String> relationshipStatuses = [
    'Single',
    'Dating',
    'In a relationship',
    'Engaged',
    'Married',
    'Complicated',
  ];

  static const List<String> interests = [
    'Love & Romance',
    'Spirituality',
    'Career',
    'Friendship',
    'Self-growth',
    'Tarot',
    'Meditation',
    'Astrology',
  ];
}
