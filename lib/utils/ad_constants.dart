import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConstants {
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  static const String _prodHomeAndroid          = 'ca-app-pub-2986638814167460/6735859966';
  static const String _prodChaptersAndroid      = 'ca-app-pub-2986638814167460/7352761461';
  static const String _prodSectionsAndroid      = 'ca-app-pub-2986638814167460/5143576691';
  static const String _prodSectionDetailAndroid = 'ca-app-pub-2986638814167460/6456658369';
  static const String _prodDictionaryAndroid       = 'ca-app-pub-2986638814167460/2820288381';
  static const String _prodJudgementsListAndroid   = 'ca-app-pub-2986638814167460/3745367562';
  static const String _prodJudgementDetailAndroid  = 'ca-app-pub-2986638814167460/7970037666';
  static const String _prodDraftsAndroid           = 'ca-app-pub-2986638814167460/7398661799';

  // TODO(ads): replace with the real iOS banner ad unit id from the AdMob
  // console (create an iOS app entry + iOS banner unit). While this is still a
  // placeholder, iOS falls back to the iOS test banner so the slot is not
  // permanently blank — see _resolve below.
  static const String _prodBannerIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Use test ads automatically in debug builds, real ads in release.
  /// Override to `true` in release only if you need to verify integration.
  static const bool _isTest = kDebugMode;

  /// True when [_prodBannerIOS] has not yet been filled in with a real id.
  static bool get _iosBannerIsPlaceholder => _prodBannerIOS.contains('XXXX');

  static String _resolve(String prodAndroid) {
    if (Platform.isAndroid) return _isTest ? _testBannerAndroid : prodAndroid;
    if (Platform.isIOS) {
      if (_isTest) return _testBannerIOS;
      if (_iosBannerIsPlaceholder) {
        // No real iOS unit configured yet: fall back to the test banner so the
        // slot renders something instead of staying blank. Replace
        // _prodBannerIOS with a real id to serve production ads on iOS.
        debugPrint(
            'AdConstants: _prodBannerIOS is still a placeholder — serving iOS '
            'test ads. Set a real iOS banner ad unit id to earn revenue.');
        return _testBannerIOS;
      }
      return _prodBannerIOS;
    }
    return '';
  }

  static String get bannerAdUnitIdHome          => _resolve(_prodHomeAndroid);
  static String get bannerAdUnitIdChapters      => _resolve(_prodChaptersAndroid);
  static String get bannerAdUnitIdSections      => _resolve(_prodSectionsAndroid);
  static String get bannerAdUnitIdSectionDetail => _resolve(_prodSectionDetailAndroid);
  static String get bannerAdUnitIdDictionary       => _resolve(_prodDictionaryAndroid);
  static String get bannerAdUnitIdJudgements       => _resolve(_prodJudgementsListAndroid);
  static String get bannerAdUnitIdJudgementDetail  => _resolve(_prodJudgementDetailAndroid);
  static String get bannerAdUnitIdDrafts           => _resolve(_prodDraftsAndroid);
}
