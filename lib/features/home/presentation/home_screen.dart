import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zodiac_utils.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/ads_service.dart';
import '../../../providers/app_providers.dart';
import 'widgets/daily_horoscope_card.dart';
import 'widgets/premium_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;
  bool _redirectedToSetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanner();
      _updateFcmToken();
    });
  }

  Future<void> _updateFcmToken() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;
    final token = await ref.read(notificationServiceProvider).getToken();
    if (token != null && token != profile.fcmToken) {
      await ref.read(userRepositoryProvider).updateFcmToken(profile.uid, token);
    }
  }

  void _loadBanner() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile?.isPremium == true) return;
    _bannerAd?.dispose();
    _bannerAd = AdsService.instance.createBannerAd(
      onLoaded: (ad) {
        if (mounted) setState(() => _bannerLoaded = true);
      },
    );
    if (_bannerAd == null) {
      // Ads not ready yet; retry after deferred init.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _loadBanner();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Loading profile...'));
            }
            // Redirect to profile setup once — not on every rebuild.
            if (!profile.isProfileComplete && !_redirectedToSetup) {
              _redirectedToSetup = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.push('/profile/setup');
              });
            }
            final sign = profile.zodiacSign ?? 'Pisces';
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${profile.displayName.split(' ').first}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.moonSilver,
                          ),
                        ),
                        const Text('Cosmic Dashboard'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            Text(
                              ZodiacUtils.emojiForSign(sign),
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sign,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    "Today's cosmic energy is rising",
                                    style: TextStyle(color: AppColors.moonSilver),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),
                        const SizedBox(height: 16),
                        if (!profile.isPremium) const PremiumBanner(),
                        const SizedBox(height: 16),
                        DailyHoroscopeCard(zodiacSign: sign),
                        const SizedBox(height: 16),
                        const _QuickActions(),
                        const SizedBox(height: 16),
                        _LoveEnergyCard(sign: sign),
                        const SizedBox(height: 16),
                        _InsightGrid(sign: sign),
                        if (_bannerLoaded && _bannerAd != null && !profile.isPremium) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.favorite,
            label: 'Match',
            onTap: () => context.push('/compatibility/new'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionChip(
            icon: Icons.chat_bubble_outline,
            label: 'AI Chat',
            onTap: () => context.push('/ai-chat'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionChip(
            icon: Icons.auto_awesome,
            label: 'Viral',
            onTap: () => context.push('/viral'),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.stellarPink),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoveEnergyCard extends ConsumerWidget {
  const _LoveEnergyCard({required this.sign});

  final String sign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(astrologyServiceProvider).getDailyHoroscope(sign),
      builder: (context, snap) {
        final energy = snap.data?.loveEnergy ?? 72;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Love Energy', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: energy / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.glassWhite,
                  color: AppColors.stellarPink,
                ),
              ),
              const SizedBox(height: 8),
              Text('$energy% — ${snap.data?.cosmicEnergy ?? "Harmonious"} vibe'),
            ],
          ),
        );
      },
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.sign});

  final String sign;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _InsightTile('Compatibility', 'Find your match', Icons.favorite, () {
          context.push('/compatibility/new');
        }),
        _InsightTile('Soulmate %', 'Calculate now', Icons.bolt, () {
          context.push('/compatibility/new');
        }),
        _InsightTile('Twin Flame', 'Detector', Icons.local_fire_department, () {
          context.push('/viral');
        }),
        _InsightTile('Celebrity', 'Your match', Icons.star, () {
          context.push('/viral');
        }),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile(this.title, this.sub, this.icon, this.onTap);

  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.auroraBlue),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.moonSilver)),
        ],
      ),
    );
  }
}
