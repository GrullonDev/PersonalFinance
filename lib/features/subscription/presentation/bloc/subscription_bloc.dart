import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:personal_finance/features/subscription/data/services/revenue_cat_service.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/services/subscription_service.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionLoad extends SubscriptionEvent {
  SubscriptionLoad(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class SubscriptionPurchasePro extends SubscriptionEvent {}

class SubscriptionRestore extends SubscriptionEvent {}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.subscription = SubscriptionEntity.free,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.purchaseSuccess = false,
    this.error,
  });

  final SubscriptionEntity subscription;
  final bool isPurchasing;
  final bool isRestoring;
  final bool purchaseSuccess;
  final String? error;

  bool get isPremium => subscription.isPremium;

  SubscriptionState copyWith({
    SubscriptionEntity? subscription,
    bool? isPurchasing,
    bool? isRestoring,
    bool? purchaseSuccess,
    String? error,
    bool clearError = false,
  }) => SubscriptionState(
    subscription: subscription ?? this.subscription,
    isPurchasing: isPurchasing ?? this.isPurchasing,
    isRestoring: isRestoring ?? this.isRestoring,
    purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props =>
      [subscription, isPurchasing, isRestoring, purchaseSuccess, error];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final RevenueCatService _revenueCat;
  final SubscriptionService _subscriptionService;

  SubscriptionBloc({
    required RevenueCatService revenueCatService,
    required SubscriptionService subscriptionService,
  }) : _revenueCat = revenueCatService,
       _subscriptionService = subscriptionService,
       super(const SubscriptionState()) {
    on<SubscriptionLoad>(_onLoad);
    on<SubscriptionPurchasePro>(_onPurchasePro);
    on<SubscriptionRestore>(_onRestore);
  }

  Future<void> _onLoad(
    SubscriptionLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _revenueCat.login(event.userId);
      final fromRevenueCat = await _revenueCat.getCurrentSubscription();

      // Si RevenueCat confirma Pro, sincronizamos Firestore también.
      if (fromRevenueCat.isPremium) {
        await _subscriptionService.save(event.userId, fromRevenueCat);
      } else {
        // Carga desde Firestore como respaldo.
        await _subscriptionService.load(event.userId);
      }

      final resolved =
          fromRevenueCat.isPremium ? fromRevenueCat : _subscriptionService.current;

      _subscriptionService.updateLocal(resolved);
      emit(state.copyWith(subscription: resolved, clearError: true));
    } catch (_) {
      // Si falla la red, confiamos en el estado local de Firestore.
      await _subscriptionService.load(event.userId);
      emit(
        state.copyWith(
          subscription: _subscriptionService.current,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _onPurchasePro(
    SubscriptionPurchasePro event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isPurchasing: true, purchaseSuccess: false, clearError: true));
    try {
      final subscription = await _revenueCat.purchasePro();
      _subscriptionService.updateLocal(subscription);
      emit(
        state.copyWith(
          subscription: subscription,
          isPurchasing: false,
          purchaseSuccess: true,
        ),
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      // El usuario canceló — no mostramos error.
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        emit(state.copyWith(isPurchasing: false, clearError: true));
      } else {
        emit(state.copyWith(isPurchasing: false, error: _mapErrorCode(code)));
      }
    } catch (e) {
      emit(state.copyWith(isPurchasing: false, error: e.toString()));
    }
  }

  Future<void> _onRestore(
    SubscriptionRestore event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isRestoring: true, clearError: true));
    try {
      final subscription = await _revenueCat.restorePurchases();
      _subscriptionService.updateLocal(subscription);
      emit(
        state.copyWith(
          subscription: subscription,
          isRestoring: false,
          purchaseSuccess: subscription.isPremium,
        ),
      );
    } on PlatformException catch (e) {
      emit(
        state.copyWith(
          isRestoring: false,
          error: _mapErrorCode(PurchasesErrorHelper.getErrorCode(e)),
        ),
      );
    } catch (e) {
      emit(state.copyWith(isRestoring: false, error: e.toString()));
    }
  }

  String _mapErrorCode(PurchasesErrorCode code) => switch (code) {
    PurchasesErrorCode.networkError =>
      'No internet connection. Please try again.',
    PurchasesErrorCode.storeProblemError =>
      'Store error. Please try again later.',
    PurchasesErrorCode.productNotAvailableForPurchaseError =>
      'Product not available. Please try again later.',
    _ => 'Purchase failed. Please try again.',
  };
}
