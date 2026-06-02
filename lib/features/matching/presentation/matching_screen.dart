import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/match_card_widget.dart';
import '../../../providers/data_providers.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  int _currentIndex = 0;

  void _handleAction(String action) {
    if (action == 'like') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liked! ❤️')),
      );
    } else if (action == 'dislike') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passed')),
      );
    } else if (action == 'superlike') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Super Liked! ⭐')),
      );
    }
    
    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final potentialMatches = ref.watch(potentialMatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Match'),
        elevation: 0,
      ),
      body: potentialMatches.when(
        data: (matches) {
          if (matches.isEmpty) {
            return _buildEmptyState(context);
          }

          final displayIndex = _currentIndex % matches.length;

          return Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayIndex + 1}/${matches.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LinearProgressIndicator(
                          value: (displayIndex + 1) / matches.length,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilters,
                    ),
                  ],
                ),
              ),
              // Card display
              Expanded(
                child: Center(
                  child: MatchCard(
                    profile: matches[displayIndex],
                    compatibilityScore: 85,
                    onLike: () => _handleAction('like'),
                    onDislike: () => _handleAction('dislike'),
                    onSuperLike: () => _handleAction('superlike'),
                  ),
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'dislike',
                      backgroundColor: Colors.grey,
                      onPressed: () => _handleAction('dislike'),
                      child: const Icon(Icons.close, size: 32),
                    ),
                    FloatingActionButton(
                      heroTag: 'superlike',
                      backgroundColor: Colors.blue,
                      onPressed: () => _handleAction('superlike'),
                      child: const Icon(Icons.star, size: 32),
                    ),
                    FloatingActionButton(
                      heroTag: 'like',
                      backgroundColor: Colors.red,
                      onPressed: () => _handleAction('like'),
                      child: const Icon(Icons.favorite, size: 32),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Matches Available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterSheet(context),
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildFilterRow('Age Range', '18 - 45'),
          const Divider(),
          _buildFilterRow('Location', '50 km'),
          const Divider(),
          _buildFilterRow('Zodiac Signs', '5 selected'),
          const Divider(),
          _buildFilterRow('Compatibility', '60% +'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
