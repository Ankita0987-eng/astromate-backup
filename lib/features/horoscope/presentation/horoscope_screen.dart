import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/app_providers.dart';

class HoroscopeScreen extends ConsumerWidget {
  const HoroscopeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final sign = profile?.zodiacSign ?? 'Pisces';

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Daily Horoscope')),
        body: FutureBuilder(
          future: ref.read(astrologyServiceProvider).getDailyHoroscope(sign),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final h = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text(
                    '$sign ✨',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Cosmic energy: ${h.cosmicEnergy}',
                    style: const TextStyle(color: AppColors.moonSilver),
                  ),
                ),
                const SizedBox(height: 24),
                _HoroscopeCard(
                  title: 'Love',
                  icon: Icons.favorite,
                  content: h.loveHoroscope,
                  color: AppColors.stellarPink,
                ),
                _HoroscopeCard(
                  title: 'Career',
                  icon: Icons.work_outline,
                  content: h.careerHoroscope,
                  color: AppColors.auroraBlue,
                ),
                _HoroscopeCard(
                  title: 'Mood',
                  icon: Icons.psychology_outlined,
                  content: h.moodInsight,
                  color: AppColors.nebulaPurple,
                ),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('Love Energy', '${h.loveEnergy}%'),
                      _Stat('Lucky #', '${h.luckyNumber}'),
                      _Stat('Color', h.luckyColor),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HoroscopeCard extends StatelessWidget {
  const _HoroscopeCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.color,
  });

  final String title;
  final IconData icon;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(height: 1.6, color: AppColors.moonSilver)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.moonSilver, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
