import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/match_profile.dart';
import '../../core/theme/app_colors.dart';

/// Swipeable match card for the matching feature.
class MatchCard extends StatefulWidget {
  final MatchProfile profile;
  final int compatibilityScore;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;

  const MatchCard({
    required this.profile,
    required this.compatibilityScore,
    required this.onLike,
    required this.onDislike,
    required this.onSuperLike,
    super.key,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Photo with fade
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.profile.photoUrls.isNotEmpty
                  ? widget.profile.photoUrls[_currentPhotoIndex]
                  : '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.deepSpace,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.nebulaPurple,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.deepSpace,
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and age
                Text(
                  '${widget.profile.displayName}, ${widget.profile.age}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.profile.location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Zodiac and compatibility
                Row(
                  children: [
                    _buildZodiacBadge(widget.profile.zodiacSign),
                    const SizedBox(width: 8),
                    _buildCompatibilityBadge(widget.compatibilityScore),
                  ],
                ),
              ],
            ),
          ),
          // Photo indicators
          if (widget.profile.photoUrls.length > 1)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(
                  widget.profile.photoUrls.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                        right: index < widget.profile.photoUrls.length - 1 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: _currentPhotoIndex == index
                            ? AppColors.nebulaPurple
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Photo navigation
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _previousPhoto,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _nextPhoto,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Positioned(
            left: 16,
            right: 16,
            bottom: -20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.close,
                  color: AppColors.stellarPink,
                  onPressed: widget.onDislike,
                  label: 'Pass',
                ),
                _buildActionButton(
                  icon: Icons.favorite,
                  color: AppColors.auroraBlue,
                  onPressed: widget.onLike,
                  label: 'Like',
                  size: 56,
                ),
                _buildActionButton(
                  icon: Icons.star,
                  color: AppColors.warning,
                  onPressed: widget.onSuperLike,
                  label: 'Super',
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.5, end: 0);
  }

  void _nextPhoto() {
    if (_currentPhotoIndex < widget.profile.photoUrls.length - 1) {
      setState(() => _currentPhotoIndex++);
    }
  }

  void _previousPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() => _currentPhotoIndex--);
    }
  }

  Widget _buildZodiacBadge(String zodiac) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.nebulaPurple.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        zodiac,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompatibilityBadge(int score) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.auroraBlue;
    } else if (score >= 60) {
      scoreColor = AppColors.nebulaPurple;
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.stellarPink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$score% Match',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
    double size = 48,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 200),
                begin: const Offset(1, 1),
                end: const Offset(0.95, 0.95),
                curve: Curves.easeInOut,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
