import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config/env_config.dart';

class BillingService {
  BillingService() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();

  Stream<PurchaseDetails> get purchases => _purchaseController.stream;

  Set<String> get productIds => {
        EnvConfig.iapMonthlyId,
        EnvConfig.iapYearlyId,
      };

  Future<bool> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('Purchase error: $e'),
    );
    return true;
  }

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() => _iap.restorePurchases();

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _purchaseController.add(purchase);
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }

  bool isPremiumProduct(String productId) =>
      productId == EnvConfig.iapMonthlyId ||
      productId == EnvConfig.iapYearlyId;

  Duration subscriptionDuration(String productId) {
    if (productId == EnvConfig.iapYearlyId) {
      return const Duration(days: 365);
    }
    return const Duration(days: 30);
  }
}
