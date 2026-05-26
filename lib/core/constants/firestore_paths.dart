class FirestorePaths {
  FirestorePaths._();

  static String user(String uid) => 'users/$uid';
  static String userCompatibilityReports(String uid) =>
      'users/$uid/compatibility_reports';
  static String compatibilityReport(String uid, String reportId) =>
      'users/$uid/compatibility_reports/$reportId';
  static String userAiChats(String uid) => 'users/$uid/ai_chats';
  static String aiChat(String uid, String chatId) =>
      'users/$uid/ai_chats/$chatId';
  static String userSubscription(String uid) => 'subscriptions/$uid';
  static String dailyHoroscope(String sign, String date) =>
      'daily_horoscopes/${sign}_$date';
}
