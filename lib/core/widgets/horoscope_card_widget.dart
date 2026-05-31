import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/horoscope_data.dart';
import '../../core/theme/app_colors.dart';

/// Widget to display a horoscope card
class HoroscopeCard extends StatefulWidget {
  final HoroscopeData horoscope;
  final String? zodiacSign;
  final VoidCallback? onSavePressed;

  const HoroscopeCard({
    required this.horoscope,
    this.zodiacSign,
    this.onSavePressed,
    super.key,
  });

  @override
  State<HoroscopeCard> createState() => _HoroscopeCardState();
}

class _HoroscopeCardState extends State<HoroscopeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark.withOpacity(0.8),
            AppColors.primaryDark.withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Horoscope text
            _buildMainText(),
            // Score indicators
            _buildScoreIndicators(),
            // Lucky items
            _buildLuckyItems(),
            // Expand/collapse and action buttons
            if (_expanded) _buildActionButtons(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.horoscope.zodiacSign} ${widget.horoscope.periodType[0].toUpperCase()}${widget.horoscope.periodType.substring(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(widget.horoscope.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainText() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.horoscope.text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreColumn('Mood', widget.horoscope.moodScore),
          _buildScoreColumn('Energy', widget.horoscope.energyScore),
          _buildScoreColumn('Love', widget.horoscope.loveScore),
          _buildScoreColumn('Health', widget.horoscope.healthScore),
          _buildScoreColumn('Wealth', widget.horoscope.wealthScore),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, int score) {
    final color = _getScoreColor(score);
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLuckyItems() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lucky Items',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLuckyItemChip(
                '🎰 ${widget.horoscope.luckyNumber}',
                'Number',
              ),
              _buildLuckyItemChip(
                '🎨 ${widget.horoscope.luckyColor}',
                'Color',
              ),
              _buildLuckyItemChip(
                '💎 ${widget.horoscope.luckyGemstone}',
                'Gemstone',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyItemChip(String label, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            type,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onSavePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save to Favorites'),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return AppColors.primary;
    if (score >= 4) return AppColors.warning;
    return AppColors.danger;
  }
}
