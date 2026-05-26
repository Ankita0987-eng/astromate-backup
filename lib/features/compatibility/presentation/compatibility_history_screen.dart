import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../providers/app_providers.dart';

class CompatibilityHistoryScreen extends ConsumerStatefulWidget {
  const CompatibilityHistoryScreen({super.key});

  @override
  ConsumerState<CompatibilityHistoryScreen> createState() =>
      _CompatibilityHistoryScreenState();
}

class _CompatibilityHistoryScreenState
    extends ConsumerState<CompatibilityHistoryScreen> {
  // Cache the stream so it is not recreated on every rebuild.
  Stream<List<CompatibilityReport>>? _reportsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStream());
  }

  void _initStream() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() {
      _reportsStream =
          ref.read(compatibilityRepositoryProvider).watchReports(user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Past Reports'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: _reportsStream == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<CompatibilityReport>>(
                stream: _reportsStream,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reports = snap.data!;
                  if (reports.isEmpty) {
                    return EmptyState(
                      title: 'No reports yet',
                      subtitle: 'Run your first compatibility check',
                      actionLabel: 'Check compatibility',
                      onAction: () => context.push('/compatibility/new'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (_, i) {
                      final r = reports[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.nebulaPurple,
                            child: Text('${r.overallScore}%'),
                          ),
                          title: Text('${r.personA.name} & ${r.personB.name}'),
                          subtitle: Text(
                            '${r.personA.zodiacSign} + ${r.personB.zodiacSign}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/compatibility/result', extra: r),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
