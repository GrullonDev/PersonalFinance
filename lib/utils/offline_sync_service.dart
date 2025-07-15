import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'pending_action.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Box<PendingAction> _actionBox;
  late StreamSubscription _connectivitySub;

  Future<void> init() async {
    _actionBox = await Hive.openBox<PendingAction>('pending_actions');
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> dispose() async {
    await _connectivitySub.cancel();
    await _actionBox.close();
  }

  Future<void> addPendingAction(PendingAction action) async {
    await _actionBox.add(action);
  }

  Future<List<PendingAction>> getPendingActions() async {
    return _actionBox.values.where((a) => a.status == 'pending').toList();
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      await syncPendingActions();
    }
  }

  Future<void> syncPendingActions() async {
    final actions = await getPendingActions();
    for (var action in actions) {
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