import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zodiac_utils.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/app_providers.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (profile) {
            if (profile == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.nebulaPurple,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (profile.zodiacSign != null)
                              Text(
                                '${ZodiacUtils.emojiForSign(profile.zodiacSign!)} ${profile.zodiacSign}',
                                style: const TextStyle(color: AppColors.moonSilver),
                              ),
                            if (profile.isPremium)
                              const Chip(
                                label: Text('Premium ✨'),
                                backgroundColor: AppColors.nebulaPurple,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoTile('Email', profile.email),
                if (profile.birthDate != null)
                  _InfoTile(
                    'Birth date',
                    DateFormat.yMMMd().format(profile.birthDate!),
                  ),
                if (profile.birthLocation != null)
                  _InfoTile('Birth place', profile.birthLocation!),
                if (profile.relationshipStatus != null)
                  _InfoTile('Status', profile.relationshipStatus!),
                if (profile.interests.isNotEmpty)
                  _InfoTile('Interests', profile.interests.join(', ')),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit profile'),
                  onTap: () => context.push('/profile/setup'),
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: const Text('Premium'),
                  onTap: () => context.push('/premium'),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Compatibility history'),
                  onTap: () => context.push('/compatibility/history'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.moonSilver)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
