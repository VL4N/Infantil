import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import '../config.dart';
import 'app_state.dart';

/// Publicidad AdMob en modo infantil.
/// Reglas de Google Play Familias: solo anuncios aptos para niños (G),
/// no personalizados y nunca durante el juego (solo en la pantalla final).
class Ads {
  static bool _ready = false;

  static Future<void> init() async {
    if (!Config.adsEnabled) return;
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        ageRestrictedTreatment: AgeRestrictedTreatment.child,
        maxAdContentRating: MaxAdContentRating.g,
      ));
      _ready = true;
    } catch (_) {}
  }

  static bool get shouldShow => _ready && Config.adsEnabled && !AppState.instance.premium;
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!Ads.shouldShow) return;
    _ad = BannerAd(
      adUnitId: Config.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null || AppState.instance.premium) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
