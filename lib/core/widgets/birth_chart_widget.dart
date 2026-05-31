import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/birth_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/astrology_calculations.dart';

/// Birth chart widget displaying a circular natal chart.
class BirthChartWidget extends StatefulWidget {
  final BirthChart birthChart;
  final bool interactive;
  final Function(String planet)? onPlanetTap;
  final double size;

  const BirthChartWidget({
    required this.birthChart,
    this.interactive = true,
    this.onPlanetTap,
    this.size = 300,
    super.key,
  });

  @override
  State<BirthChartWidget> createState() => _BirthChartWidgetState();
}

class _BirthChartWidgetState extends State<BirthChartWidget> {
  String? selectedPlanet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Natal chart circle
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primaryDark.withOpacity(0.1),
                AppColors.primaryDark.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: CustomPaint(
            painter: NatalChartPainter(
              birthChart: widget.birthChart,
              selectedPlanet: selectedPlanet,
            ),
            size: Size(widget.size, widget.size),
          ),
        ),
        const SizedBox(height: 16),
        // Planet info display
        if (selectedPlanet != null)
          _buildPlanetInfo(selectedPlanet!)
        else
          _buildChartSummary(),
      ],
    );
  }

  void _selectPlanet(String planet) {
    setState(() {
      selectedPlanet = selectedPlanet == planet ? null : planet;
    });
    widget.onPlanetTap?.call(planet);
  }

  Widget _buildPlanetInfo(String planet) {
    final planetPos = widget.birthChart.planets[planet];
    if (planetPos == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            planet,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Sign', planetPos.sign),
          _buildInfoRow(
            'Degree',
            '${planetPos.degree.toStringAsFixed(1)}°',
          ),
          _buildInfoRow(
            'House',
            '${planetPos.house}',
          ),
          if (planetPos.isRetrograde)
            _buildInfoRow('Status', '♻️ Retrograde'),
          const SizedBox(height: 8),
          Text(
            AstrologyCalculations.getPlanetInterpretation(
              planet,
              planetPos.sign,
            ),
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow('Sun Sign', widget.birthChart.sunSign),
          _buildSummaryRow('Moon Sign', widget.birthChart.moonSign),
          _buildSummaryRow('Ascendant', widget.birthChart.ascendant),
          _buildSummaryRow(
            'Cosmic Energy',
            '${widget.birthChart.cosmicEnergy.toStringAsFixed(1)}/100',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing the natal chart
class NatalChartPainter extends CustomPainter {
  final BirthChart birthChart;
  final String? selectedPlanet;

  NatalChartPainter({
    required this.birthChart,
    this.selectedPlanet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw background zodiac circle
    _drawZodiacCircle(canvas, center, radius);

    // Draw houses
    _drawHouses(canvas, center, radius);

    // Draw planets
    _drawPlanets(canvas, center, radius);

    // Draw aspects
    _drawAspects(canvas, center, radius);
  }

  void _drawZodiacCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);

    // Draw zodiac signs
    const signs = AstrologyCalculations.zodiacSigns;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * (math.pi / 180);
      final x = center.dx + (radius + 30) * math.cos(angle);
      final y = center.dy + (radius + 30) * math.sin(angle);

      textPainter.text = TextSpan(
        text: signs[i].substring(0, 3),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawHouses(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.secondary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final house in birthChart.houses.values) {
      final startAngle = (house.startDegree - 90) * (math.pi / 180);
      final endAngle = (house.endDegree - 90) * (math.pi / 180);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  void _drawPlanets(Canvas canvas, Offset center, double radius) {
    const planetSymbols = {
      'Sun': '☉',
      'Moon': '☽',
      'Mercury': '☿',
      'Venus': '♀',
      'Mars': '♂',
      'Jupiter': '♃',
      'Saturn': '♄',
      'Uranus': '♅',
      'Neptune': '♆',
      'Pluto': '♇',
    };

    for (final entry in birthChart.planets.entries) {
      final planet = entry.key;
      final position = entry.value;

      final angle = (position.totalDegree - 90) * (math.pi / 180);
      final x = center.dx + (radius - 40) * math.cos(angle);
      final y = center.dy + (radius - 40) * math.sin(angle);

      // Draw planet circle
      final isSelected = planet == selectedPlanet;
      final paint = Paint()
        ..color = isSelected ? AppColors.success : AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), isSelected ? 10 : 8, paint);

      // Draw planet symbol
      final textPainter = TextPainter(
        text: TextSpan(
          text: planetSymbols[planet] ?? planet[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );

      // Draw retrograde symbol
      if (position.isRetrograde) {
        final retroPaint = TextPainter(
          text: const TextSpan(
            text: '℞',
            style: TextStyle(color: AppColors.warning, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        retroPaint.layout();
        retroPaint.paint(
          canvas,
          Offset(x + 8, y - 8),
        );
      }
    }
  }

  void _drawAspects(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final aspect in birthChart.aspects) {
      final planet1 = birthChart.planets[aspect.planet1];
      final planet2 = birthChart.planets[aspect.planet2];

      if (planet1 == null || planet2 == null) continue;

      final angle1 = (planet1.totalDegree - 90) * (math.pi / 180);
      final angle2 = (planet2.totalDegree - 90) * (math.pi / 180);

      final x1 = center.dx + (radius - 40) * math.cos(angle1);
      final y1 = center.dy + (radius - 40) * math.sin(angle1);
      final x2 = center.dx + (radius - 40) * math.cos(angle2);
      final y2 = center.dy + (radius - 40) * math.sin(angle2);

      // Color based on aspect type
      paint.color = _getAspectColor(aspect.type).withOpacity(0.3);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint,
      );
    }
  }

  Color _getAspectColor(String aspectType) {
    switch (aspectType) {
      case 'trine':
      case 'sextile':
        return AppColors.success;
      case 'square':
      case 'opposition':
        return AppColors.danger;
      case 'conjunction':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
