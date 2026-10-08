import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import 'app_state.dart';

/// Compra única de Premium mediante Google Play Billing.
class Billing extends ChangeNotifier {
  Billing._();
  static final instance = Billing._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool busy = false;
  ProductDetails? product;
  String? error;

  String get price => product?.price ?? Config.fallbackPrice;

  Future<void> init() async {
    try {
      available = await _iap.isAvailable();
      if (!available) return;
      _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => _fail('$e'));
      final resp = await _iap.queryProductDetails({Config.premiumProductId});
      product = resp.productDetails.isEmpty ? null : resp.productDetails.first;
      // Recupera Premium si ya se compró antes (otro teléfono o reinstalación).
      await _iap.restorePurchases();
    } catch (e) {
      available = false;
    }
    notifyListeners();
  }

  Future<void> buy() async {
    error = null;
    if (product == null) {
      _fail('La tienda no está disponible. Revisa tu conexión e inténtalo de nuevo.');
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product!));
    } catch (e) {
      _fail('No se pudo iniciar la compra.');
    }
  }

  Future<void> restore() async {
    error = null;
    if (!available) {
      _fail('La tienda no está disponible.');
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != Config.premiumProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          AppState.instance.setPremium(true);
          busy = false;
        case PurchaseStatus.error:
          _fail('La compra no se completó.');
        case PurchaseStatus.canceled:
          busy = false;
        case PurchaseStatus.pending:
          // Pago en efectivo / pendiente: Google avisará cuando se confirme.
          break;
      }
      // Google Play reembolsa las compras que no se confirman en 3 días.
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  void _fail(String message) {
    error = message;
    busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
