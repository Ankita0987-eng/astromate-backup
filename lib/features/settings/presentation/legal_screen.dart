import 'package:flutter/material.dart';
import '../../../core/widgets/cosmic_background.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? 'Privacy Policy' : 'Terms & Conditions';
    final body = isPrivacy ? _privacyText : _termsText;

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(body, style: const TextStyle(height: 1.6)),
        ),
      ),
    );
  }
}

const _privacyText = '''
Cosmic Match Privacy Policy
Last updated: 2026

We collect account information (email, profile, birth data) to provide astrology compatibility and AI features.

Data storage: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics, Messaging).

Third parties: OpenAI (AI chat), Astrology API (optional), Google Ads, Google Play Billing.

You may delete your account in Settings. Contact: support@cosmicmatch.app

We do not sell personal data. See full policy before Play Store publication.
''';

const _termsText = '''
Cosmic Match Terms & Conditions

Cosmic Match provides entertainment and wellness-oriented astrology content, not professional medical, legal, or relationship advice.

Subscriptions renew per Google Play terms. Refunds follow Play Store policies.

You must be 18+ or have parental consent where required.

Misuse, harassment, or automated scraping is prohibited.

By using Cosmic Match you agree to these terms.
''';
