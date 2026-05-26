import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/config/env_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/app_providers.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  List<ProductDetails> _products = [];
  bool _loading = true;
  StreamSubscription<PurchaseDetails>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final billing = ref.read(billingServiceProvider);
    await billing.initialize();
    _purchaseSub = billing.purchases.listen(_onPurchase);
    final products = await billing.loadProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _loading = false;
      });
    }
  }

  Future<void> _onPurchase(PurchaseDetails purchase) async {
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final billing = ref.read(billingServiceProvider);
    final duration = billing.subscriptionDuration(purchase.productID);
    await ref.read(userRepositoryProvider).setPremium(
          user.uid,
          isPremium: true,
          expiresAt: DateTime.now().add(duration),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Cosmic Premium! ✨')),
      );
      context.pop();
    }
  }

  Future<void> _buy(String productId) async {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not available. Configure Play Console IDs.'),
        ),
      );
      return;
    }
    await ref.read(billingServiceProvider).buy(product);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Cosmic Premium'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 64)),
                    Text(
                      profile?.isPremium == true
                          ? 'You are Premium'
                          : 'Unlock the full cosmos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const _FeatureRow('Unlimited compatibility checks'),
                    const _FeatureRow('Full premium reports'),
                    const _FeatureRow('Unlimited AI astrology chat'),
                    const _FeatureRow('Advanced insights'),
                    const _FeatureRow('No ads'),
                    const SizedBox(height: 32),
                    GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'Monthly',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _priceFor(EnvConfig.iapMonthlyId) ?? '\$9.99/mo',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stellarPink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Subscribe Monthly',
                            onPressed: profile?.isPremium == true
                                ? null
                                : () => _buy(EnvConfig.iapMonthlyId),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      gradient: AppColors.premiumGradient,
                      child: Column(
                        children: [
                          const Text(
                            'Yearly — Best Value',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _priceFor(EnvConfig.iapYearlyId) ?? '\$59.99/yr',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Subscribe Yearly',
                            onPressed: profile?.isPremium == true
                                ? null
                                : () => _buy(EnvConfig.iapYearlyId),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(billingServiceProvider).restore(),
                      child: const Text('Restore purchases'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _priceFor(String id) {
    return _products.where((p) => p.id == id).firstOrNull?.price;
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.auroraBlue, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
