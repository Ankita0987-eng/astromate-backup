import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/subscription_plan.dart';
import '../../../providers/data_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plans = ref.watch(subscriptionPlansProvider);
    final currentSubscription = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Plans'),
        elevation: 0,
      ),
      body: plans.when(
        data: (subscriptionPlans) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Unlock Your Cosmic Potential',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get unlimited access to premium features',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                // Plans
                ...subscriptionPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPlanCard(
                    context,
                    plan,
                    isDark,
                  ),
                )).toList(),
                const SizedBox(height: 16),
                // Features list
                _buildFeaturesSection(context, isDark),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    bool isDark,
  ) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final isPopular = plan.order == 2; // Gold tier

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? Colors.purple : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${plan.monthlyPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Features
          ...plan.features.take(3).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
          if (plan.features.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${plan.features.length - 3} more features',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.purple,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleSubscribe(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.purple : Colors.grey.shade300,
              ),
              child: Text(
                'Subscribe Now',
                style: TextStyle(
                  color: isPopular ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium Features',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem('Unlimited Compatibility Reports', context),
          _buildFeatureItem('Advanced Chart Analysis', context),
          _buildFeatureItem('Daily AI Consultations', context),
          _buildFeatureItem('Exclusive Insights', context),
          _buildFeatureItem('Priority Support', context),
          _buildFeatureItem('Ad-Free Experience', context),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(BuildContext context, SubscriptionPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscribe to ${plan.name} for \$${plan.monthlyPrice}/month'),
      ),
    );
    // TODO: Integrate in-app purchases
  }
}
