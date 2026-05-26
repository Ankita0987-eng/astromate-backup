import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zodiac_utils.dart';
import '../../../core/widgets/cosmic_background.dart';
import '../../../data/models/compatibility_report.dart';

class ShareCardScreen extends StatefulWidget {
  const ShareCardScreen({super.key, this.report});

  final CompatibilityReport? report;

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final _cardKey = GlobalKey();

  Future<void> _share() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cosmic_match_card.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check our cosmic compatibility on Cosmic Match ✨',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    if (report == null) {
      return CosmicBackground(
        child: Scaffold(
          appBar: AppBar(title: const Text('Share')),
          body: const Center(child: Text('No report to share')),
        ),
      );
    }

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Share Card'),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: _share),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.nebulaPurple.withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Cosmic Match',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${report.personA.name} & ${report.personB.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ZodiacUtils.emojiForSign(report.personA.zodiacSign)} ${report.personA.zodiacSign}  +  ${ZodiacUtils.emojiForSign(report.personB.zodiacSign)} ${report.personB.zodiacSign}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${report.soulmatePercentage}%',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Soulmate Match',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ShareStat('Match', '${report.overallScore}%'),
                        _ShareStat('Twin Flame', '${report.twinFlameScore}%'),
                        _ShareStat('Love', '${report.romanticScore}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Couple energy: Electric ✨',
                      style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
