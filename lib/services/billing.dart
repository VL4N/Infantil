import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import '../logic/lang.dart';
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
      await loadProduct();
      // Recupera Premium si ya se compró antes (otro teléfono o reinstalación).
      await _iap.restorePurchases();
    } catch (e) {
      available = false;
    }
    notifyListeners();
  }

  /// Pide a Google Play el producto Premium. Se vuelve a intentar al abrir la pantalla
  /// Premium y al tocar comprar: un producto recién activado puede tardar en aparecer,
  /// y sin internet al abrir la app tampoco llega.
  Future<void> loadProduct() async {
    if (product != null) return;
    try {
      if (!available) {
        available = await _iap.isAvailable();
        if (!available) return;
        _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => _fail('$e'));
      }
      final resp = await _iap.queryProductDetails({Config.premiumProductId});
      product = resp.productDetails.isEmpty ? null : resp.productDetails.first;
    } catch (_) {
      product = null;
    }
    notifyListeners();
  }

  Future<void> buy() async {
    error = null;
    if (product == null) {
      busy = true;
      notifyListeners();
      await loadProduct();
    }
    if (product == null) {
      _fail(available
          ? tr('Premium todavía no está disponible en Google Play. Inténtalo más tarde.',
              "Premium isn't available on Google Play yet. Please try again later.")
          : tr('No se pudo conectar con Google Play. Revisa tu conexión e inténtalo de nuevo.',
              "Couldn't connect to Google Play. Check your connection and try again."));
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product!));
    } catch (e) {
      _fail(tr('No se pudo iniciar la compra.', "Couldn't start the purchase."));
    }
  }

  Future<void> restore() async {
    error = null;
    if (!available) {
      _fail(tr('La tienda no está disponible.', 'The store is not available.'));
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
          _fail(tr('La compra no se completó.', "The purchase wasn't completed."));
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
