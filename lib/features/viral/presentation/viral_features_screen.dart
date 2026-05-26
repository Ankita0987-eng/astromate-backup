import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/app_providers.dart';

class ViralFeaturesScreen extends ConsumerWidget {
  const ViralFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final sign = profile?.zodiacSign ?? 'Pisces';
    final astrology = ref.read(astrologyServiceProvider);
    final celebrity = astrology.celebrityMatch(sign);
    final matches = astrology.bestZodiacMatches(sign).take(5).toList();

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Cosmic Extras'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥 Twin Flame Detector',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Run a compatibility check to reveal twin flame score and intense soul connection indicators.',
                    style: TextStyle(color: AppColors.moonSilver, height: 1.5),
                  ),
                  TextButton(
                    onPressed: () => context.push('/compatibility/new'),
                    child: const Text('Detect now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚩 Relationship Red Flags',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Every compatibility report includes personalized red flags based on your zodiac dynamics.',
                    style: TextStyle(color: AppColors.moonSilver, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⭐ Celebrity Match',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'As a $sign, your celebrity cosmic twin is $celebrity!',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💫 Best Zodiac Matches',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ...matches.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(m.key)),
                          Text(
                            '${m.value}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.stellarPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: FutureBuilder(
                future: astrology.getDailyHoroscope(sign),
                builder: (_, snap) {
                  final energy = snap.data?.cosmicEnergy ?? 'Mystical';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Cosmic Energy",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        '$energy — Love energy at ${snap.data?.loveEnergy ?? 70}%',
                        style: const TextStyle(color: AppColors.moonSilver, height: 1.5),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
