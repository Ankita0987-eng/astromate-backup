import 'package:intl/intl.dart';

/// Zodiac calculations and compatibility helpers.
class ZodiacUtils {
  ZodiacUtils._();

  static String signFromDate(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Scorpio';
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Sagittarius';
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Capricorn';
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Aquarius';
    }
    return 'Pisces';
  }

  static String emojiForSign(String sign) {
    const map = {
      'Aries': '♈',
      'Taurus': '♉',
      'Gemini': '♊',
      'Cancer': '♋',
      'Leo': '♌',
      'Virgo': '♍',
      'Libra': '♎',
      'Scorpio': '♏',
      'Sagittarius': '♐',
      'Capricorn': '♑',
      'Aquarius': '♒',
      'Pisces': '♓',
    };
    return map[sign] ?? '✨';
  }

  static int elementIndex(String sign) {
    const fire = ['Aries', 'Leo', 'Sagittarius'];
    const earth = ['Taurus', 'Virgo', 'Capricorn'];
    const air = ['Gemini', 'Libra', 'Aquarius'];
    if (fire.contains(sign)) return 0;
    if (earth.contains(sign)) return 1;
    if (air.contains(sign)) return 2;
    return 3; // water
  }

  /// Deterministic compatibility seed from two signs + names.
  static int compatibilitySeed(String sign1, String sign2, String name1, String name2) {
    final combined = '$sign1$sign2$name1$name2'.toLowerCase();
    return combined.codeUnits.fold(0, (a, b) => a + b) % 10000;
  }

  static String formatBirthDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String formatBirthTime(DateTime time) =>
      DateFormat('h:mm a').format(time);
}
