import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/horoscope_data.dart';
import '../../../providers/data_providers.dart';

class HoroscopeScreen extends ConsumerStatefulWidget {
  const HoroscopeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends ConsumerState<HoroscopeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horoscope'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(context, isDark),
          _buildWeeklyTab(context, isDark),
          _buildMonthlyTab(context, isDark),
          _buildYearlyTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDailyTab(BuildContext context, bool isDark) {
    final birthChart = ref.watch(currentUserBirthChartProvider);
    
    return birthChart.when(
      data: (chart) {
        if (chart == null) {
          return Center(
            child: Text(
              'Complete your birth chart first',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildHoroscopeTab('daily', chart.zodiacSign, context, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildWeeklyTab(BuildContext context, bool isDark) {
    final birthChart = ref.watch(currentUserBirthChartProvider);
    
    return birthChart.when(
      data: (chart) {
        if (chart == null) {
          return Center(
            child: Text(
              'Complete your birth chart first',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildHoroscopeTab('weekly', chart.zodiacSign, context, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildMonthlyTab(BuildContext context, bool isDark) {
    final birthChart = ref.watch(currentUserBirthChartProvider);
    
    return birthChart.when(
      data: (chart) {
        if (chart == null) {
          return Center(
            child: Text(
              'Complete your birth chart first',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildHoroscopeTab('monthly', chart.zodiacSign, context, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildYearlyTab(BuildContext context, bool isDark) {
    final birthChart = ref.watch(currentUserBirthChartProvider);
    
    return birthChart.when(
      data: (chart) {
        if (chart == null) {
          return Center(
            child: Text(
              'Complete your birth chart first',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildHoroscopeTab('yearly', chart.zodiacSign, context, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildHoroscopeTab(String periodType, String zodiacSign, BuildContext context, bool isDark) {
    final horoscopeProvider = _getHoroscopeProvider(periodType, zodiacSign);
    final horoscope = ref.watch(horoscopeProvider);
    
    return horoscope.when(
      data: (data) {
        if (data == null) {
          return Center(
            child: Text(
              'No $periodType horoscope available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return _buildHoroscopeContent(data, context, isDark);
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
              Text('Error loading horoscope: $err'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoroscopeContent(HoroscopeData data, BuildContext context, bool isDark) {
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.zodiacSign,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildScoresGrid(data, context, bgColor),
          const SizedBox(height: 16),
          _buildLuckyItems(data, context, bgColor),
        ],
      ),
    );
  }

  Widget _buildScoresGrid(HoroscopeData data, BuildContext context, Color? bgColor) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Energy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              children: [
                _buildScoreItem('Mood', data.moodScore, context),
                _buildScoreItem('Energy', data.energyScore, context),
                _buildScoreItem('Love', data.loveScore, context),
                _buildScoreItem('Health', data.healthScore, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, BuildContext context) {
    Color scoreColor;
    if (score >= 8) {
      scoreColor = Colors.green;
    } else if (score >= 6) {
      scoreColor = Colors.blue;
    } else if (score >= 4) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 10,
          color: scoreColor,
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('$score/10', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scoreColor)),
      ],
    );
  }

  Widget _buildLuckyItems(HoroscopeData data, BuildContext context, Color? bgColor) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lucky Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLuckyBadge('Number', data.luckyNumber.toString(), context),
                _buildLuckyBadge('Color', data.luckyColor, context),
                _buildLuckyBadge('Gemstone', data.luckyGemstone, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyBadge(String label, String value, BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  FutureProvider<HoroscopeData?> _getHoroscopeProvider(String periodType, String zodiacSign) {
    switch (periodType) {
      case 'daily':
        return dailyHoroscopeProvider(zodiacSign);
      case 'weekly':
        return weeklyHoroscopeProvider(zodiacSign);
      case 'monthly':
        return monthlyHoroscopeProvider(zodiacSign);
      case 'yearly':
        return yearlyHoroscopeProvider(zodiacSign);
      default:
        return dailyHoroscopeProvider(zodiacSign);
    }
  }
}
