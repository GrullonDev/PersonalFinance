import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:personal_finance/core/services/update_policy.dart';

/// Registro de la última versión publicada por plataforma en Firestore
/// (`app_meta/versions`).
///
/// La primera instalación de una versión nueva desde TestFlight o la tienda
/// la anota aquí; así el resto de usuarios recibe el aviso de actualización
/// sin tener que editar Remote Config a mano en cada publicación.
class AppVersionRegistry {
  AppVersionRegistry({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('app_meta').doc('versions');

  Future<AppVersion> latest(String platform) async {
    try {
      final snap = await _doc.get();
      return AppVersion.parse('${snap.data()?[platform] ?? ''}');
    } catch (e) {
      developer.log('AppVersionRegistry: no se pudo leer: $e');
      return const AppVersion('', 0);
    }
  }

  /// Anota [installed] si es más nueva que la registrada.
  Future<void> report(String platform, AppVersion installed) async {
    if (installed.isEmpty) return;
    try {
      final current = await latest(platform);
      if (!current.isEmpty && !(current < installed)) return;
      await _doc.set({
        platform: versionTag(installed),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('AppVersionRegistry: no se pudo registrar: $e');
    }
  }
}
