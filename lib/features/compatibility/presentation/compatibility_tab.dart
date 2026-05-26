import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/glass_card.dart';

class CompatibilityTab extends StatelessWidget {
  const CompatibilityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Compatibility')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const GlassCard(
                child: Column(
                  children: [
                    Icon(Icons.favorite, size: 48, color: AppColors.stellarPink),
                    SizedBox(height: 16),
                    Text(
                      'Discover your cosmic connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter their birth details to generate soulmate %, scores, and AI insights.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.moonSilver),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GradientButton(
                label: 'New Compatibility Check',
                icon: Icons.add,
                onPressed: () => context.push('/compatibility/new'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/compatibility/history'),
                child: const Text('View past reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
