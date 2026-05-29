import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:personal_finance/features/subscription/data/datasources/revenue_cat_service.dart';
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

// Evento interno — emitido por el stream de Firestore.
class _SubscriptionUpdated extends SubscriptionEvent {
  _SubscriptionUpdated(this.subscription);
  final SubscriptionEntity subscription;
  @override
  List<Object?> get props => [subscription];
}

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
  List<Object?> get props => [
    subscription,
    isPurchasing,
    isRestoring,
    purchaseSuccess,
    error,
  ];
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
    on<_SubscriptionUpdated>(_onUpdated);
  }

  Future<void> _onLoad(
    SubscriptionLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    // ── Paso 1: Firestore es la fuente principal ─────────────────────────────
    // Se carga y emite de inmediato, sin depender de RevenueCat.
    try {
      await _subscriptionService.load(event.userId);
    } catch (_) {
      // Si Firestore falla en cold-start, _current queda en free.
    }
    emit(
      state.copyWith(
        subscription: _subscriptionService.current,
        clearError: true,
      ),
    );

    // ── Paso 2: Suscribir al stream de Firestore para actualizaciones en tiempo real.
    emit.forEach<SubscriptionEntity>(
      _subscriptionService.watch(event.userId),
      onData: (entity) {
        _subscriptionService.updateLocal(entity);
        return state.copyWith(subscription: entity, clearError: true);
      },
      onError: (_, __) => state,
    );
  }

  // Manejador del stream interno (actualización en tiempo real desde Firestore).
  void _onUpdated(
    _SubscriptionUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    _subscriptionService.updateLocal(event.subscription);
    emit(state.copyWith(subscription: event.subscription, clearError: true));
  }

  Future<void> _onPurchasePro(
    SubscriptionPurchasePro event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      state.copyWith(
        isPurchasing: true,
        purchaseSuccess: false,
        clearError: true,
      ),
    );
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
      'Sin conexión a internet. Por favor, intenta de nuevo.',
    PurchasesErrorCode.storeProblemError =>
      'Error en la tienda. Por favor, intenta más tarde.',
    PurchasesErrorCode.productNotAvailableForPurchaseError =>
      'Producto no disponible en este momento. Intenta más tarde.',
    _ => 'La compra no se pudo completar. Por favor, intenta de nuevo.',
  };
}
