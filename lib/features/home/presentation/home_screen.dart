import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/horoscope_card_widget.dart';
import '../../../core/widgets/match_card_widget.dart';
import '../../../data/models/horoscope_data.dart';
import '../../../data/models/match_profile.dart';
import '../../../providers/data_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userBirthChart = ref.watch(currentUserBirthChartProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Cosmic Match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: userBirthChart.when(
        data: (chart) {
          if (chart == null) {
            return _buildOnboardingPrompt(context);
          }
          return _buildDashboard(context, isDark, chart);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $err'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 64, color: Colors.purple),
          const SizedBox(height: 24),
          Text(
            'Welcome to Cosmic Match',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your birth chart to unlock your cosmic profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/birth-chart'),
            child: const Text('Create Birth Chart'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, bool isDark, dynamic chart) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(context, isDark, chart),
            const SizedBox(height: 24),
            _buildCosmicEnergySection(context, isDark),
            const SizedBox(height: 24),
            _buildHoroscopeSection(context, isDark),
            const SizedBox(height: 24),
            _buildRecommendedMatchesSection(context, isDark),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, bool isDark, dynamic chart) {
    final bgColor = isDark ? Colors.grey[900] : Colors.purple.shade50;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.pink.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getTimeOfDay()}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            chart.sunSign != null ? '${chart.sunSign} Native' : 'Cosmic Seeker',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGreetingMetric('Birth Chart', '✓', Colors.white),
              _buildGreetingMetric('Profile', '90%', Colors.white),
              _buildGreetingMetric('Matches', '12', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicEnergySection(BuildContext context, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Cosmic Energy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          color: bgColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: CosmicEnergyPainter(),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Energy Score: 78/100',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Excellent day for new connections',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoroscopeSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Horoscope',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            GestureDetector(
              onTap: () => context.push('/horoscope'),
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final mockHoroscope = HoroscopeData(
                id: 'daily_$index',
                zodiacSign: 'Libra',
                periodType: 'daily',
                text: 'Today brings new opportunities for connection and growth. Trust your instincts.',
                luckyNumber: 7,
                luckyColor: 'Purple',
                luckyGemstone: 'Amethyst',
                moodScore: 8,
                energyScore: 7,
                loveScore: 9,
                healthScore: 8,
                wealthScore: 7,
                date: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(days: 1)),
              );
              
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: HoroscopeCard(
                  horoscope: mockHoroscope,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedMatchesSection(BuildContext context, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended for You',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            GestureDetector(
              onTap: () => context.push('/matching'),
              child: Text(
                'See All',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final mockProfile = MatchProfile(
                userId: 'user_$index',
                displayName: 'Alex',
                age: 26,
                gender: 'Female',
                location: 'San Francisco',
                photoUrls: [],
                zodiacSign: 'Libra',
                moonSign: 'Leo',
                ascendant: 'Sagittarius',
                interests: ['Music', 'Travel', 'Adventure'],
                bio: 'Adventure seeker, love music and travel',
                relationshipGoal: 'Serious relationship',
                isVerified: true,
                createdAt: DateTime.now(),
                lastActive: DateTime.now(),
              );
              
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: MatchCard(
                  profile: mockProfile,
                  compatibilityScore: 92,
                  onLike: () {},
                  onDislike: () {},
                  onSuperLike: () {},
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.favorite,
                label: 'Find Matches',
                onTap: () => context.push('/matching'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.chat,
                label: 'Messages',
                onTap: () => context.push('/messages'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.auto_awesome,
                label: 'AI Astro',
                onTap: () => context.push('/ai-chat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.card_membership,
                label: 'Premium',
                onTap: () => context.push('/subscription'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.purple),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class CosmicEnergyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw energy circles
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, radius - (i * 15), paint);
    }

    // Draw energy arc (78%)
    final arcPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14,
      (3.14 * 2 * 0.78),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(CosmicEnergyPainter oldDelegate) => false;
}
