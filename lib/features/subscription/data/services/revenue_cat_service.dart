import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:personal_finance/core/config/revenue_cat_config.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';

class RevenueCatService {
  static Future<void> initialize() async {
    final config = PurchasesConfiguration(
      Platform.isIOS
          ? RevenueCatConfig.appleApiKey
          : RevenueCatConfig.googleApiKey,
    );
    await Purchases.configure(config);
  }

  /// Identifica al usuario en RevenueCat al hacer login.
  Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }

  /// Elimina la identidad al hacer logout.
  Future<void> logout() async {
    await Purchases.logOut();
  }

  /// Retorna la oferta mensual activa o null si no hay conexión / no configurado.
  Future<Package?> getMonthlyPackage() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.monthly;
  }

  /// Compra el plan Pro. Lanza [PurchasesErrorCode] en caso de error.
  /// Retorna la entidad actualizada según el resultado.
  Future<SubscriptionEntity> purchasePro() async {
    final package = await getMonthlyPackage();
    if (package == null) {
      throw Exception('No monthly package available');
    }
    final customerInfo = await Purchases.purchasePackage(package);
    return _toEntity(customerInfo);
  }

  /// Restaura compras anteriores en este dispositivo / cuenta.
  Future<SubscriptionEntity> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    return _toEntity(customerInfo);
  }

  /// Consulta el estado actual de la suscripción desde RevenueCat.
  Future<SubscriptionEntity> getCurrentSubscription() async {
    final customerInfo = await Purchases.getCustomerInfo();
    return _toEntity(customerInfo);
  }

  SubscriptionEntity _toEntity(CustomerInfo info) {
    final entitlement = info.entitlements.active[RevenueCatConfig.entitlementId];

    if (entitlement == null) return SubscriptionEntity.free;

    return SubscriptionEntity(
      tier: PlanTier.pro,
      status: SubscriptionStatus.active,
      expiresAt: entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null,
      purchasedAt: DateTime.tryParse(entitlement.latestPurchaseDate),
      productId: entitlement.productIdentifier,
    );
  }
}
