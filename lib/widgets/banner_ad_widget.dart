import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;

  const BannerAdWidget({super.key, required this.adUnitId});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  // Retry a failed load with exponential backoff so a slow/intermittent
  // connection eventually fills the slot instead of leaving it blank for the
  // whole screen visit. Capped so a hard failure (no-fill / invalid id) does
  // not retry forever.
  static const int _maxRetries = 5;

  BannerAd? _ad;
  bool _loaded = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _loadAd();
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded: unit=${widget.adUnitId} '
              'responseId=${ad.responseInfo?.responseId} '
              'mediation=${ad.responseInfo?.mediationAdapterClassName}');
          _retryAttempt = 0;
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          // Log the real reason so blank ad slots can be diagnosed.
          // code 3 = no fill (account/serving issue, integration is fine);
          // code 1 = invalid request (often a wrong/disabled ad unit id);
          // code 2 = network error (common on slow internet — retried below).
          debugPrint('BannerAd FAILED: unit=${widget.adUnitId} '
              'code=${error.code} domain=${error.domain} '
              'message=${error.message} '
              'responseInfo=${ad.responseInfo}');
          ad.dispose();
          _ad = null;
          if (!mounted || _retryAttempt >= _maxRetries) return;
          // Exponential backoff capped at 30s: ~2s, 4s, 8s, 16s, 30s.
          final delay = Duration(seconds: min(1 << (_retryAttempt + 1), 30));
          _retryAttempt++;
          debugPrint('BannerAd retry $_retryAttempt/$_maxRetries '
              'in ${delay.inSeconds}s: unit=${widget.adUnitId}');
          _retryTimer = Timer(delay, () {
            if (mounted) _loadAd();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
