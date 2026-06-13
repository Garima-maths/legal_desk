import 'dart:io';

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

  static const String _prodBannerIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  static const bool _isTest = false;

  static String _resolve(String prodAndroid) {
    if (Platform.isAndroid) return _isTest ? _testBannerAndroid : prodAndroid;
    if (Platform.isIOS) return _isTest ? _testBannerIOS : _prodBannerIOS;
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
