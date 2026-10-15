import 'package:flutter/foundation.dart';

abstract final class AdMobIds {
  static const _iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _androidTestInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  static const _iosProductionInterstitial = String.fromEnvironment(
    'ca-app-pub-1088575488587821/1475587904',
  );
  static const _androidProductionInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
  );

  static String? get interstitial {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _idForPlatform(
        production: _iosProductionInterstitial,
        test: _iosTestInterstitial,
      ),
      TargetPlatform.android => _idForPlatform(
        production: _androidProductionInterstitial,
        test: _androidTestInterstitial,
      ),
      _ => null,
    };
  }

  static String? _idForPlatform({
    required String production,
    required String test,
  }) {
    if (production.isNotEmpty) return production;
    return kReleaseMode ? null : test;
  }
}
