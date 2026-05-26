import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zodiac_utils.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../data/models/compatibility_report.dart';

class CompatibilityResultScreen extends StatelessWidget {
  const CompatibilityResultScreen({super.key, required this.report});

  final CompatibilityReport report;

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Compatibility Report'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => context.push('/share', extra: report),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(report: report).animate().fadeIn(),
              const SizedBox(height: 24),
              CircularPercentIndicator(
                radius: 90,
                lineWidth: 12,
                percent: report.overallScore / 100,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${report.overallScore}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Overall', style: TextStyle(color: AppColors.moonSilver)),
                  ],
                ),
                progressColor: AppColors.stellarPink,
                backgroundColor: AppColors.glassWhite,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniScore('Soulmate', report.soulmatePercentage),
                  _MiniScore('Twin Flame', report.twinFlameScore),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: _ScoresChart(report: report),
              ),
              const SizedBox(height: 16),
              _ScoreRow('Emotional', report.emotionalScore),
              _ScoreRow('Communication', report.communicationScore),
              _ScoreRow('Romantic', report.romanticScore),
              _ScoreRow('Long-term', report.longTermScore),
              const SizedBox(height: 16),
              GlassCard(
                child: Text(
                  report.summary,
                  style: const TextStyle(height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              _SectionList(title: 'Strengths', items: report.strengths, icon: Icons.check_circle, color: AppColors.auroraBlue),
              _SectionList(title: 'Weaknesses', items: report.weaknesses, icon: Icons.info_outline, color: AppColors.moonSilver),
              _SectionList(title: 'Red Flags', items: report.redFlags, icon: Icons.warning_amber, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Share Cosmic Card',
                icon: Icons.share,
                onPressed: () => context.push('/share', extra: report),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report});
  final CompatibilityReport report;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(ZodiacUtils.emojiForSign(report.personA.zodiacSign), style: const TextStyle(fontSize: 32)),
                Text(report.personA.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(report.personA.zodiacSign, style: const TextStyle(color: AppColors.moonSilver)),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: AppColors.stellarPink, size: 32),
          Expanded(
            child: Column(
              children: [
                Text(ZodiacUtils.emojiForSign(report.personB.zodiacSign), style: const TextStyle(fontSize: 32)),
                Text(report.personB.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(report.personB.zodiacSign, style: const TextStyle(color: AppColors.moonSilver)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Text('$value%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.moonSilver, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.score);
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppColors.glassWhite,
                color: AppColors.nebulaPurple,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$score%'),
        ],
      ),
    );
  }
}

class _ScoresChart extends StatelessWidget {
  const _ScoresChart({required this.report});
  final CompatibilityReport report;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  const labels = ['Emo', 'Comm', 'Rom', 'Long'];
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const Text('');
                  return Text(labels[i], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _bar(0, report.emotionalScore.toDouble()),
            _bar(1, report.communicationScore.toDouble()),
            _bar(2, report.romanticScore.toDouble()),
            _bar(3, report.longTermScore.toDouble()),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppColors.cosmicGradient,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
