import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_plan.dart';

/// Repository for managing subscription and billing data.
class SubscriptionRepository {
  SubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  static const String _plansCollection = 'subscription_plans';
  static const String _userSubscriptionsCollection = 'user_subscriptions';
  static const String _billingCollection = 'billing_transactions';

  /// Get all available subscription plans
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      final docs = await _firestore
          .collection(_plansCollection)
          .orderBy('order', descending: false)
          .get();
      
      return docs.docs.map((doc) => SubscriptionPlan.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream available subscription plans
  Stream<List<SubscriptionPlan>> watchAvailablePlans() {
    return _firestore
        .collection(_plansCollection)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionPlan.fromFirestore(doc))
            .toList());
  }

  /// Get a specific subscription plan
  Future<SubscriptionPlan?> getPlan(String planId) async {
    try {
      final doc = await _firestore
          .collection(_plansCollection)
          .doc(planId)
          .get();
      
      if (!doc.exists) return null;
      return SubscriptionPlan.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's current subscription
  Future<UserSubscription?> getCurrentSubscription() async {
    try {
      final doc = await _firestore
          .collection(_userSubscriptionsCollection)
          .doc(_userId)
          .get();
      
      if (!doc.exists) return null;
      return UserSubscription.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream user's subscription updates
  Stream<UserSubscription?> watchSubscription() {
    return _firestore
        .collection(_userSubscriptionsCollection)
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.exists ? UserSubscription.fromFirestore(doc) : null);
  }

  /// Update user subscription
  Future<void> updateSubscription(UserSubscription subscription) async {
    try {
      await _firestore
          .collection(_userSubscriptionsCollection)
          .doc(_userId)
          .set(subscription.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Create new subscription
  Future<UserSubscription> createSubscription(
    String planId,
    String planName,
    bool autoRenew,
  ) async {
    try {
      final plan = await getPlan(planId);
      if (plan == null) throw Exception('Plan not found');
      
      final now = DateTime.now();
      final renewalDate = now.add(const Duration(days: 30));
      
      final subscription = UserSubscription(
        userId: _userId,
        planId: planId,
        planName: planName,
        startDate: now,
        renewalDate: renewalDate,
        isActive: true,
        autoRenew: autoRenew,
        reportsUsed: 0,
        aiMessagesUsed: 0,
        chatsUsed: 0,
        lastBillingDate: now,
      );
      
      await updateSubscription(subscription);
      return subscription;
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) throw Exception('No active subscription');
      
      await _firestore
          .collection(_userSubscriptionsCollection)
          .doc(_userId)
          .update({
            'isActive': false,
            'autoRenew': false,
            'cancellationDate': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Record a billing transaction
  Future<BillingTransaction> recordTransaction(
    String planId,
    double amount,
    String paymentMethod,
    String status,
  ) async {
    try {
      final docRef = _firestore.collection(_billingCollection).doc();
      
      final transaction = BillingTransaction(
        id: docRef.id,
        userId: _userId,
        planId: planId,
        amount: amount,
        currency: 'USD',
        paymentMethod: paymentMethod,
        status: status,
        description: 'Plan upgrade/renewal',
        transactionDate: DateTime.now(),
      );
      
      await docRef.set(transaction.toMap());
      return transaction;
    } catch (e) {
      rethrow;
    }
  }

  /// Get billing history
  Future<List<BillingTransaction>> getBillingHistory({int limit = 50}) async {
    try {
      final docs = await _firestore
          .collection(_billingCollection)
          .where('userId', isEqualTo: _userId)
          .orderBy('transactionDate', descending: true)
          .limit(limit)
          .get();
      
      return docs.docs.map((doc) => BillingTransaction.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has premium access
  Future<bool> hasPremiumAccess() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) return false;
      
      return subscription.isActive && !subscription.isExpired;
    } catch (e) {
      rethrow;
    }
  }

  /// Get remaining usage for current subscription
  Future<Map<String, int>> getRemainingUsage() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        return {
          'reportsRemaining': 0,
          'aiMessagesRemaining': 0,
          'chatsRemaining': 0,
        };
      }
      
      final plan = await getPlan(subscription.planId);
      if (plan == null) {
        return {
          'reportsRemaining': 0,
          'aiMessagesRemaining': 0,
          'chatsRemaining': 0,
        };
      }
      
      return {
        'reportsRemaining': (plan.monthlyReports - subscription.reportsUsed).clamp(0, plan.monthlyReports),
        'aiMessagesRemaining': (plan.monthlyAIMessages - subscription.aiMessagesUsed).clamp(0, plan.monthlyAIMessages),
        'chatsRemaining': (plan.monthlyChats - subscription.chatsUsed).clamp(0, plan.monthlyChats),
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Increment usage counter
  Future<void> incrementUsage(String usageType) async {
    try {
      await _firestore
          .collection(_userSubscriptionsCollection)
          .doc(_userId)
          .update({usageType: FieldValue.increment(1)});
    } catch (e) {
      rethrow;
    }
  }
}
