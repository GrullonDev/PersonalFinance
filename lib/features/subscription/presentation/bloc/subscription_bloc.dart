import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Evento interno — emitido al cerrar sesión.
class _SubscriptionReset extends SubscriptionEvent {}

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
  StreamSubscription<SubscriptionEntity>? _firestoreSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _userId;

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
    on<_SubscriptionReset>(_onReset);

    // Auto-carga basada en auth: si el usuario ya está autenticado al construir
    // el bloc, despacha SubscriptionLoad de inmediato. Luego escucha cambios
    // futuros (login/logout) para recargar o resetear.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      add(SubscriptionLoad(currentUser.uid));
    }
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        add(SubscriptionLoad(user.uid));
      } else {
        add(_SubscriptionReset());
      }
    });
  }

  Future<void> _onLoad(
    SubscriptionLoad event,
    Emitter<SubscriptionState> emit,
  ) async {
    _userId = event.userId;

    // Cancelar suscripción previa antes de crear una nueva.
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;

    // ── Paso 0: Identificar al usuario en RevenueCat ─────────────────────────
    // Sin esto, RevenueCat usa un ID anónimo y no puede confirmar la suscripción.
    try {
      await _revenueCat.login(event.userId);
    } catch (_) {}

    // ── Paso 1: Firestore es la fuente principal ─────────────────────────────
    try {
      await _subscriptionService.load(event.userId);
    } catch (_) {}
    emit(
      state.copyWith(
        subscription: _subscriptionService.current,
        clearError: true,
      ),
    );

    // ── Paso 2: Si Firestore dice Free, reconciliar con RevenueCat ───────────
    // Cubre el caso donde la compra se completó pero no se guardó en Firestore.
    if (!_subscriptionService.current.isPremium) {
      try {
        final rcSubscription = await _revenueCat.getCurrentSubscription();
        if (rcSubscription.isPremium) {
          await _subscriptionService.save(event.userId, rcSubscription);
          emit(state.copyWith(subscription: rcSubscription, clearError: true));
        }
      } catch (_) {}
    }

    // ── Paso 3: Stream de Firestore para actualizaciones en tiempo real ───────
    // onError evita que el stream muera silenciosamente si fromMap lanza.
    _firestoreSubscription = _subscriptionService
        .watch(event.userId)
        .listen(
          (entity) => add(_SubscriptionUpdated(entity)),
          onError: (_) {},
          cancelOnError: false,
        );
  }

  // Manejador del stream interno (actualizaciones en tiempo real desde Firestore).
  void _onUpdated(
    _SubscriptionUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    _subscriptionService.updateLocal(event.subscription);
    emit(state.copyWith(subscription: event.subscription, clearError: true));
  }

  // Manejador de logout — resetea al estado free y cancela el stream.
  Future<void> _onReset(
    _SubscriptionReset event,
    Emitter<SubscriptionState> emit,
  ) async {
    await _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _userId = null;
    _subscriptionService.updateLocal(SubscriptionEntity.free);
    emit(const SubscriptionState());
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

      // Persistir en Firestore para que reinicios de app lean el estado correcto.
      if (_userId != null) {
        await _subscriptionService.save(_userId!, subscription);
      }

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

      // Persistir en Firestore para que reinicios de app lean el estado correcto.
      if (_userId != null) {
        await _subscriptionService.save(_userId!, subscription);
      }

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

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await _firestoreSubscription?.cancel();
    return super.close();
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
