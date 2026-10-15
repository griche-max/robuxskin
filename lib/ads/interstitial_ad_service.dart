import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';

class InterstitialAdService {
  InterstitialAdService._();

  static final InterstitialAdService instance = InterstitialAdService._();

  static const _exportsPerAd = 2;

  InterstitialAd? _interstitial;
  Future<void>? _initialization;
  bool _loading = false;
  bool _readyToRequestAds = false;
  int _successfulExports = 0;

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> initialize() {
    if (!_isMobilePlatform || AdMobIds.interstitial == null) {
      return Future.value();
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _updateConsent();
      _readyToRequestAds = await ConsentInformation.instance.canRequestAds();
      if (!_readyToRequestAds) return;
      await MobileAds.instance.initialize();
      _loadInterstitial();
    } catch (_) {
      // Ads are optional. Editing and export must continue if consent or the
      // advertising SDK is unavailable.
    }
  }

  Future<void> _updateConsent() {
    final completer = Completer<void>();
    var completed = false;

    void complete() {
      if (completed) return;
      completed = true;
      completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) => complete());
      },
      (_) => complete(),
    );
    return completer.future;
  }

  void _loadInterstitial() {
    final adUnitId = AdMobIds.interstitial;
    if (!_readyToRequestAds || adUnitId == null || _loading) return;
    if (_interstitial != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  Future<void> recordSuccessfulExport() async {
    if (!_isMobilePlatform) return;
    await initialize();
    if (!_readyToRequestAds) return;

    _successfulExports++;
    if (_successfulExports < _exportsPerAd) {
      _loadInterstitial();
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    _successfulExports = 0;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      ad.dispose();
      _loadInterstitial();
    }
  }

  Future<bool> showPrivacyOptions() async {
    if (!_isMobilePlatform || AdMobIds.interstitial == null) return false;
    await initialize();
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (status != PrivacyOptionsRequirementStatus.required) return false;

    final completer = Completer<bool>();
    await ConsentForm.showPrivacyOptionsForm(
      (error) => completer.complete(error == null),
    );
    return completer.future;
  }
}
