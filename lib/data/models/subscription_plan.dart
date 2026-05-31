import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Subscription tier definition.
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.monthlyReports,
    required this.monthlyAIMessages,
    required this.monthlyChats,
    required this.dailyHoroscopeEnabled,
    required this.advancedChartAnalysis,
    required this.prioritySupport,
    required this.adFree,
    required this.order,
  });

  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final int monthlyReports;
  final int monthlyAIMessages;
  final int monthlyChats;
  final bool dailyHoroscopeEnabled;
  final bool advancedChartAnalysis;
  final bool prioritySupport;
  final bool adFree;
  final int order;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'features': features,
      'monthlyReports': monthlyReports,
      'monthlyAIMessages': monthlyAIMessages,
      'monthlyChats': monthlyChats,
      'dailyHoroscopeEnabled': dailyHoroscopeEnabled,
      'advancedChartAnalysis': advancedChartAnalysis,
      'prioritySupport': prioritySupport,
      'adFree': adFree,
      'order': order,
    };
  }

  factory SubscriptionPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlan(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      monthlyPrice: (data['monthlyPrice'] as num?)?.toDouble() ?? 0.0,
      yearlyPrice: (data['yearlyPrice'] as num?)?.toDouble() ?? 0.0,
      features: List<String>.from(data['features'] as List? ?? []),
      monthlyReports: data['monthlyReports'] as int? ?? 0,
      monthlyAIMessages: data['monthlyAIMessages'] as int? ?? 0,
      monthlyChats: data['monthlyChats'] as int? ?? 0,
      dailyHoroscopeEnabled: data['dailyHoroscopeEnabled'] as bool? ?? false,
      advancedChartAnalysis: data['advancedChartAnalysis'] as bool? ?? false,
      prioritySupport: data['prioritySupport'] as bool? ?? false,
      adFree: data['adFree'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, monthlyPrice];
}

/// User's subscription details.
class UserSubscription extends Equatable {
  const UserSubscription({
    required this.userId,
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.renewalDate,
    required this.isActive,
    required this.autoRenew,
    required this.reportsUsed,
    required this.aiMessagesUsed,
    required this.chatsUsed,
    required this.lastBillingDate,
    this.cancellationDate,
  });

  final String userId;
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime renewalDate;
  final bool isActive;
  final bool autoRenew;
  final int reportsUsed;
  final int aiMessagesUsed;
  final int chatsUsed;
  final DateTime lastBillingDate;
  final DateTime? cancellationDate;

  bool get isExpired => DateTime.now().isAfter(renewalDate);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'startDate': Timestamp.fromDate(startDate),
      'renewalDate': Timestamp.fromDate(renewalDate),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'reportsUsed': reportsUsed,
      'aiMessagesUsed': aiMessagesUsed,
      'chatsUsed': chatsUsed,
      'lastBillingDate': Timestamp.fromDate(lastBillingDate),
      'cancellationDate': cancellationDate != null ? Timestamp.fromDate(cancellationDate!) : null,
    };
  }

  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSubscription(
      userId: doc.id,
      planId: data['planId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      renewalDate: (data['renewalDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      isActive: data['isActive'] as bool? ?? false,
      autoRenew: data['autoRenew'] as bool? ?? true,
      reportsUsed: data['reportsUsed'] as int? ?? 0,
      aiMessagesUsed: data['aiMessagesUsed'] as int? ?? 0,
      chatsUsed: data['chatsUsed'] as int? ?? 0,
      lastBillingDate: (data['lastBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancellationDate: (data['cancellationDate'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [userId, planId, isActive, renewalDate];
}

/// Billing transaction record.
class BillingTransaction extends Equatable {
  const BillingTransaction({
    required this.id,
    required this.userId,
    required this.planId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status, // success, failed, pending
    required this.description,
    required this.transactionDate,
  });

  final String id;
  final String userId;
  final String planId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String description;
  final DateTime transactionDate;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'description': description,
      'transactionDate': Timestamp.fromDate(transactionDate),
    };
  }

  factory BillingTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillingTransaction(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String? ?? '',
      transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, status, transactionDate];
}
