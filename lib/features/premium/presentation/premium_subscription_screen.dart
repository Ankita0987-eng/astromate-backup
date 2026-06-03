import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/data_providers.dart';

class PremiumSubscriptionScreen extends ConsumerWidget {
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSubscription = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        elevation: 0,
      ),
      body: currentSubscription.when(
        data: (subscription) {
          if (subscription == null || !subscription.isActive) {
            return _buildNoPremium(context, isDark);
          }
          return _buildPremiumInfo(context, isDark, subscription);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildNoPremium(BuildContext context, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upgrade to Premium',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildBenefitsSection(context, bgColor),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening subscription plans...')),
                );
              },
              child: const Text('View Premium Plans'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInfo(BuildContext context, bool isDark, dynamic subscription) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final daysRemaining = subscription.renewalDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active subscription info
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Plan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subscription.planName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '$daysRemaining days left',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Renews on ${subscription.renewalDate.toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Usage section
          Text(
            'Usage This Month',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildUsageItem(
            context,
            'Compatibility Reports',
            subscription.reportsUsed,
            10,
            bgColor,
          ),
          const SizedBox(height: 12),
          _buildUsageItem(
            context,
            'AI Messages',
            subscription.aiMessagesUsed,
            100,
            bgColor,
          ),
          const SizedBox(height: 12),
          _buildUsageItem(
            context,
            'Chats',
            subscription.chatsUsed,
            50,
            bgColor,
          ),
          const SizedBox(height: 32),
          // Billing info
          Text(
            'Billing',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBillingRow('Last Billing Date', '${subscription.lastBillingDate.toString().split(' ')[0]}', context),
                  const SizedBox(height: 12),
                  _buildBillingRow('Auto-Renew', subscription.autoRenew ? 'Enabled' : 'Disabled', context),
                  const SizedBox(height: 12),
                  _buildBillingRow('Status', subscription.isActive ? 'Active' : 'Inactive', context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening billing history...')),
                    );
                  },
                  child: const Text('View Billing History'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Subscription?'),
                        content: const Text(
                          'You will lose access to premium features at the end of your billing cycle.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Keep'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Subscription cancelled')),
                              );
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context, Color? bgColor) {
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
            'Premium Includes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildBenefitItem('Unlimited Compatibility Reports', context),
          _buildBenefitItem('Advanced Birth Chart Analysis', context),
          _buildBenefitItem('Daily AI Consultations', context),
          _buildBenefitItem('Exclusive Zodiac Insights', context),
          _buildBenefitItem('Priority Support', context),
          _buildBenefitItem('Ad-Free Experience', context),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String label,
    int used,
    int limit,
    Color? bgColor,
  ) {
    final percentage = (used / limit * 100).clamp(0, 100).toDouble();

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '$used/$limit',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                percentage > 80 ? Colors.red : Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
