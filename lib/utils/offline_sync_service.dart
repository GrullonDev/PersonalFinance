import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import 'package:personal_finance/utils/pending_action.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box<PendingAction> _actionBox;
  late StreamSubscription<ConnectivityResult> _connectivitySub;

  Future<void> init() async {
    _actionBox = await Hive.openBox<PendingAction>('pending_actions');
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  Future<void> dispose() async {
    await _connectivitySub.cancel();
    await _actionBox.close();
  }

  Future<void> addPendingAction(PendingAction action) async {
    await _actionBox.add(action);
  }

  Future<List<PendingAction>> getPendingActions() async =>
      _actionBox.values
          .where((PendingAction a) => a.status == 'pending')
          .toList();

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      await syncPendingActions();
    }
  }

  Future<void> syncPendingActions() async {
    final List<PendingAction> actions = await getPendingActions();
    for (PendingAction action in actions) {
      try {
        // Aquí deberías llamar a tu backend según el tipo de acción
        // await sendToBackend(action);
        action.status = 'sent';
        await action.save();
      } catch (e) {
        action.status = 'error';
        await action.save();
      }
    }
  }
}
