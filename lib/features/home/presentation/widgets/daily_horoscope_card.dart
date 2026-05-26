import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../providers/app_providers.dart';

class DailyHoroscopeCard extends ConsumerWidget {
  const DailyHoroscopeCard({super.key, required this.zodiacSign});

  final String zodiacSign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(astrologyServiceProvider).getDailyHoroscope(zodiacSign),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const GlassCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final h = snap.data!;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.stellarPink, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Love Horoscope',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                h.loveHoroscope,
                style: const TextStyle(height: 1.5, color: AppColors.moonSilver),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip('Lucky #${h.luckyNumber}'),
                  const SizedBox(width: 8),
                  _Chip(h.luckyColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
