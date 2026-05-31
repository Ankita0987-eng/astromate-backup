import 'package:intl/intl.dart';

/// Comprehensive validators for the astrology app.
class AppValidators {
  /// Validate birth date - must be in past and reasonable age
  static String? validateBirthDate(DateTime? date) {
    if (date == null) return 'Birth date is required';
    
    final now = DateTime.now();
    if (date.isAfter(now)) return 'Birth date cannot be in the future';
    
    final age = now.year - date.year;
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 150) return 'Please enter a valid birth date';
    
    return null;
  }

  /// Validate birth time (24-hour format)
  static String? validateBirthTime(String? time) {
    if (time == null || time.isEmpty) return null; // Optional
    
    final pattern = RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]$');
    if (!pattern.hasMatch(time)) {
      return 'Birth time must be in HH:MM format (24-hour)';
    }
    
    return null;
  }

  /// Validate birth location - not empty and reasonable length
  static String? validateBirthLocation(String? location) {
    if (location == null || location.isEmpty) {
      return 'Birth location is required';
    }
    
    if (location.length < 2) {
      return 'Birth location must be at least 2 characters';
    }
    
    if (location.length > 100) {
      return 'Birth location must be less than 100 characters';
    }
    
    return null;
  }

  /// Validate zodiac sign
  static String? validateZodiacSign(String? sign) {
    if (sign == null || sign.isEmpty) return 'Zodiac sign is required';
    
    const validSigns = [
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
      'Pisces'
    ];
    
    if (!validSigns.contains(sign)) {
      return 'Invalid zodiac sign';
    }
    
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    
    final pattern = RegExp(
      r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );
    
    if (!pattern.hasMatch(email)) return 'Please enter a valid email address';
    
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    
    return null;
  }

  /// Validate display name
  static String? validateDisplayName(String? name) {
    if (name == null || name.isEmpty) return 'Name is required';
    
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 50) return 'Name must be less than 50 characters';
    
    if (!RegExp(r'^[a-zA-Z\s\-\']+$').hasMatch(name)) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  /// Validate gender
  static String? validateGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'Gender is required';
    
    const validGenders = ['Male', 'Female', 'Other', 'Prefer not to say'];
    if (!validGenders.contains(gender)) return 'Invalid gender';
    
    return null;
  }

  /// Validate age in range
  static String? validateAgeRange(int? age, {int minAge = 18, int maxAge = 100}) {
    if (age == null) return 'Age is required';
    if (age < minAge) return 'Minimum age is $minAge';
    if (age > maxAge) return 'Maximum age is $maxAge';
    
    return null;
  }

  /// Validate compatibility score
  static String? validateCompatibilityScore(int? score) {
    if (score == null) return 'Compatibility score is required';
    if (score < 0 || score > 100) {
      return 'Compatibility score must be between 0 and 100';
    }
    
    return null;
  }

  /// Validate latitude
  static String? validateLatitude(double? lat) {
    if (lat == null) return 'Latitude is required';
    if (lat < -90 || lat > 90) return 'Latitude must be between -90 and 90';
    
    return null;
  }

  /// Validate longitude
  static String? validateLongitude(double? lon) {
    if (lon == null) return 'Longitude is required';
    if (lon < -180 || lon > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  }

  /// Validate message content
  static String? validateMessageContent(String? content) {
    if (content == null || content.isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (content.length > 10000) {
      return 'Message is too long (max 10000 characters)';
    }
    
    return null;
  }

  /// Validate bio/description
  static String? validateBio(String? bio) {
    if (bio != null && bio.length > 500) {
      return 'Bio must be less than 500 characters';
    }
    
    return null;
  }

  /// Validate interests list
  static String? validateInterests(List<String>? interests) {
    if (interests == null || interests.isEmpty) {
      return 'Please select at least one interest';
    }
    
    if (interests.length > 20) {
      return 'You can select up to 20 interests';
    }
    
    for (final interest in interests) {
      if (interest.length > 50) {
        return 'Each interest must be less than 50 characters';
      }
    }
    
    return null;
  }

  /// Validate relationship goal
  static String? validateRelationshipGoal(String? goal) {
    if (goal == null || goal.isEmpty) return 'Relationship goal is required';
    
    const validGoals = [
      'Dating',
      'Long-term relationship',
      'Marriage',
      'Friendship',
      'Not sure'
    ];
    
    if (!validGoals.contains(goal)) return 'Invalid relationship goal';
    
    return null;
  }

  /// Validate phone number format
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return null; // Optional
    
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 10) return 'Please enter a valid phone number';
    if (cleaned.length > 15) return 'Phone number is too long';
    
    return null;
  }

  /// Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    final monthDiff = today.month - birthDate.month;
    
    if (monthDiff < 0 || (monthDiff == 0 && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Format birth date for display
  static String formatBirthDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format birth time for display
  static String formatBirthTime(DateTime? time) {
    if (time == null) return 'Not specified';
    return DateFormat('hh:mm a').format(time);
  }

  /// Get zodiac sign from birth date
  static String getZodiacSign(DateTime birthDate) {
    const signs = [
      'Capricorn',
      'Aquarius',
      'Pisces',
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn'
    ];
    
    const daysInMonths = [20, 19, 21, 20, 21, 21, 23, 23, 23, 23, 22, 22, 20];
    
    int signIndex = (birthDate.month - 1) * 1 + 
        (birthDate.day >= daysInMonths[birthDate.month - 1] ? 1 : 0);
    
    return signs[signIndex];
  }
}
