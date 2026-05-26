import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/env_config.dart';

/// AdMob wrapper with test-ID fallbacks and non-blocking initialization.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _interstitialCounter = 0;

  /// Safe to call multiple times; failures are logged and ignored.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
      if (kDebugMode) {
        debugPrint('AdsService: initialized (banner=${bannerAdUnitId})');
      }
    } catch (e, st) {
      debugPrint('AdsService: initialize failed: $e\n$st');
    }
  }

  String get bannerAdUnitId => EnvConfig.admobBannerId;

  String get _interstitialId => EnvConfig.admobInterstitialId;

  String get _rewardedId => EnvConfig.admobRewardedId;

  BannerAd? createBannerAd({required void Function(Ad) onLoaded}) {
    if (!_initialized) return null;

    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdsService: banner failed: $error');
          ad.dispose();
        },
      ),
    );
    ad.load();
    return ad;
  }

  void _loadInterstitial() {
    if (!_initialized) return;

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdsService: interstitial load failed: $error');
          _interstitial = null;
        },
      ),
    );
  }

  Future<void> maybeShowInterstitial() async {
    if (!_initialized) return;
    _interstitialCounter++;
    if (_interstitialCounter % 4 != 0) return;
    try {
      await _interstitial?.show();
    } catch (e) {
      debugPrint('AdsService: interstitial show failed: $e');
    }
    _interstitial = null;
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (!_initialized) return;

    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          debugPrint('AdsService: rewarded load failed: $error');
          _rewarded = null;
        },
      ),
    );
  }

  Future<bool> showRewarded({required void Function() onReward}) async {
    if (!_initialized) {
      await initialize();
    }

    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (rewarded) onReward();
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, __) => rewarded = true);
    } catch (e) {
      debugPrint('AdsService: rewarded show failed: $e');
      return false;
    }

    _rewarded = null;
    return rewarded;
  }
}
