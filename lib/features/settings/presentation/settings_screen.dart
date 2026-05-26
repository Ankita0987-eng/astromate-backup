import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark mode'),
              subtitle: Text(themeMode == 'dark' ? 'On' : 'Off'),
              value: themeMode == 'dark',
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
            ListTile(
              title: const Text('Manage subscription'),
              leading: const Icon(Icons.workspace_premium),
              onTap: () => context.push('/premium'),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              leading: const Icon(Icons.privacy_tip_outlined),
              onTap: () => context.push('/legal/privacy'),
            ),
            ListTile(
              title: const Text('Terms & Conditions'),
              leading: const Icon(Icons.description_outlined),
              onTap: () => context.push('/legal/terms'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Log out'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth/login');
              },
            ),
            ListTile(
              title: const Text('Delete account', style: TextStyle(color: Colors.redAccent)),
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, reports, and chats. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(userRepositoryProvider).deleteUserData(user.uid);
      await ref.read(authServiceProvider).deleteAccount();
      if (context.mounted) context.go('/auth/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Re-authenticate then try again: $e')),
        );
      }
    }
  }
}
