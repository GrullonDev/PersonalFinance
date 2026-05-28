import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

/// Mapper bidireccional entre [TransactionEntity] y los documentos Firestore.
///
/// ## Contexto — dos schemas en la misma colección
///
/// La colección `users/{uid}/transactions` es escrita por dos sistemas:
///
/// | Campo          | Schema MVP (Quick Finance)   | Schema Legacy (Backend)  |
/// |----------------|------------------------------|--------------------------|
/// | tipo           | `type: "income"\|"expense"`  | `tipo: "ingreso"\|"gasto"` |
/// | monto          | `amount: double`             | `monto: double`          |
/// | descripción    | `note: string`               | `descripcion: string`    |
/// | fecha          | `createdAt: ISO8601`         | `fecha: "YYYY-MM-DD"`    |
/// | categoría      | — (ausente en entidad)       | `categoria_id: string`   |
/// | recurrencia    | — (ausente en entidad)       | `es_recurrente: bool`    |
/// | control sync   | `syncStatus/version/deviceId`| — (ausente)              |
/// | soft-delete    | `deletedAt: ISO8601`         | — (ausente)              |
///
/// ## Estrategia del mapper
///
/// - **[fromFirestore]**: detecta el schema automáticamente y normaliza
///   hacia [TransactionEntity]. Campos del legacy sin equivalente en la
///   entidad se preservan en [TransactionFirestoreExtras].
///
/// - **[toFirestore]**: produce el schema canónico unificado, compatible
///   con el `SyncManager` y con la lectura del backend.
///
/// ## Schema canónico de escritura
/// ```
/// users/{uid}/transactions/{id}
/// ├── id              : string        (= doc ID)
/// ├── userId          : string
/// ├── type            : "income"|"expense"
/// ├── amount          : number
/// ├── note            : string
/// ├── createdAt       : ISO8601 string
/// ├── updatedAt       : ISO8601 string
/// ├── deletedAt       : ISO8601 string | null
/// ├── syncStatus      : "pending"|"synced"|"failed"
/// ├── version         : int
/// ├── deviceId        : string
/// ├── serverTimestamp : FieldValue (solo en escritura)
/// ├── categoryId      : string | null   (extensión)
/// ├── isRecurring     : bool            (extensión)
/// └── profileId       : string | null   (extensión)
/// ```
class TransactionFirestoreMapper {
  const TransactionFirestoreMapper._();

  // ── Constantes de campo (schema canónico) ─────────────────────────────────

  static const _fId = 'id';
  static const _fUserId = 'userId';
  static const _fType = 'type';
  static const _fAmount = 'amount';
  static const _fNote = 'note';
  static const _fCreatedAt = 'createdAt';
  static const _fUpdatedAt = 'updatedAt';
  static const _fDeletedAt = 'deletedAt';
  static const _fSyncStatus = 'syncStatus';
  static const _fVersion = 'version';
  static const _fDeviceId = 'deviceId';

  // Extensiones compatibles con el backend legacy
  static const _fCategoryId = 'categoryId';
  static const _fIsRecurring = 'isRecurring';
  static const _fProfileId = 'profileId';

  // ── Aliases legacy ────────────────────────────────────────────────────────

  static const _legacyTipo = 'tipo';
  static const _legacyMonto = 'monto';
  static const _legacyDescripcion = 'descripcion';
  static const _legacyFecha = 'fecha';
  static const _legacyCategoriaId = 'categoria_id';
  static const _legacyEsRecurrente = 'es_recurrente';
  static const _legacyProfileId = 'profile_id';

  // ── fromFirestore ─────────────────────────────────────────────────────────

  /// Convierte un documento Firestore (mapa de campos) a [TransactionEntity].
  ///
  /// Detecta automáticamente si el documento sigue el schema **MVP** o el
  /// **legacy** mediante la presencia de las claves `type` / `tipo`.
  ///
  /// [docId] es el ID del documento en Firestore; se usa como `id` de la
  /// entidad si el campo `id` no está en el mapa.
  ///
  /// El parámetro extras recibe los campos del legacy que no existen en [TransactionEntity]
  /// (categoryId, isRecurring, profileId). Permite que el repositorio los
  /// persista o los ignore según la capa de negocio.
  static ({TransactionEntity entity, TransactionFirestoreExtras extras})
  fromFirestore(Map<String, dynamic> data, {required String docId}) {
    final isLegacy = !data.containsKey(_fType) && data.containsKey(_legacyTipo);

    final entity =
        isLegacy
            ? _fromLegacy(data, docId: docId)
            : _fromMvp(data, docId: docId);

    final extras = TransactionFirestoreExtras(
      categoryId: _str(data[_fCategoryId] ?? data[_legacyCategoriaId]),
      isRecurring: _bool(data[_fIsRecurring] ?? data[_legacyEsRecurrente]),
      profileId: _str(data[_fProfileId] ?? data[_legacyProfileId]),
    );

    return (entity: entity, extras: extras);
  }

  // ── toFirestore ───────────────────────────────────────────────────────────

  /// Serializa [entity] al schema canónico listo para escritura en Firestore.
  ///
  /// [extras] permite incluir campos extendidos (categoryId, isRecurring,
  /// profileId) si están disponibles en la capa de presentación.
  ///
  /// **Nota**: `serverTimestamp` debe agregarse en el datasource usando
  /// `FieldValue.serverTimestamp()` — no se incluye aquí para evitar la
  /// dependencia de `cloud_firestore` en la capa de dominio.
  static Map<String, dynamic> toFirestore(
    TransactionEntity entity, {
    TransactionFirestoreExtras extras = const TransactionFirestoreExtras(),
  }) => {
    _fId: entity.id,
    _fUserId: entity.userId,
    _fType: _typeToString(entity.type),
    _fAmount: entity.amount,
    _fNote: entity.note,
    _fCreatedAt: entity.createdAt.toIso8601String(),
    _fUpdatedAt: entity.updatedAt.toIso8601String(),
    _fDeletedAt: entity.deletedAt?.toIso8601String(),
    _fSyncStatus: _syncStatusToString(entity.syncStatus),
    _fVersion: entity.version,
    _fDeviceId: entity.deviceId,
    // Extensiones opcionales — null se omite si no hay valor
    if (extras.categoryId != null) _fCategoryId: extras.categoryId,
    if (extras.isRecurring != null) _fIsRecurring: extras.isRecurring,
    if (extras.profileId != null) _fProfileId: extras.profileId,
  };

  // ── Parsers internos ──────────────────────────────────────────────────────

  static TransactionEntity _fromMvp(
    Map<String, dynamic> data, {
    required String docId,
  }) => TransactionEntity(
    id: _str(data[_fId]) ?? docId,
    userId: _str(data[_fUserId]) ?? '',
    type: _typeFromString(data[_fType]),
    amount: _double(data[_fAmount]),
    note: _str(data[_fNote]) ?? '',
    categoryId: _str(data[_fCategoryId] ?? data[_legacyCategoriaId]),
    createdAt: _dateTime(data[_fCreatedAt]) ?? DateTime.now(),
    updatedAt: _dateTime(data[_fUpdatedAt]) ?? DateTime.now(),
    deletedAt: _dateTime(data[_fDeletedAt]),
    syncStatus: _syncStatusFromString(data[_fSyncStatus]),
    version: _int(data[_fVersion]),
    deviceId: _str(data[_fDeviceId]) ?? '',
  );

  static TransactionEntity _fromLegacy(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    // "ingreso" → income, cualquier otra cosa → expense
    final type =
        (data[_legacyTipo] as String? ?? '').toLowerCase() == 'ingreso'
            ? TransactionType.income
            : TransactionType.expense;

    // El legacy guarda la fecha como "YYYY-MM-DD"; createdAt se usa para ello
    final fecha = _dateFromDateString(data[_legacyFecha] as String?);

    return TransactionEntity(
      id: _str(data[_fId]) ?? docId,
      userId: '', // el legacy no almacena userId en el documento
      type: type,
      amount: _double(data[_legacyMonto]),
      note: _str(data[_legacyDescripcion]) ?? '',
      categoryId: _str(data[_legacyCategoriaId] ?? data[_fCategoryId]),
      createdAt: fecha ?? DateTime.now(),
      updatedAt: fecha ?? DateTime.now(),
      syncStatus:
          SyncStatus.synced, // si viene del server, ya está sincronizado
      version: 1,
      deviceId: '', // el legacy no registra deviceId
    );
  }

  // ── Helpers de conversión ─────────────────────────────────────────────────

  static String _typeToString(TransactionType type) =>
      type == TransactionType.income ? 'income' : 'expense';

  static TransactionType _typeFromString(dynamic raw) {
    final s = (raw as String? ?? '').toLowerCase();
    return s == 'income' || s == 'ingreso'
        ? TransactionType.income
        : TransactionType.expense;
  }

  static String _syncStatusToString(SyncStatus status) => switch (status) {
    SyncStatus.pending => 'pending',
    SyncStatus.synced => 'synced',
    SyncStatus.failed => 'failed',
  };

  static SyncStatus _syncStatusFromString(dynamic raw) =>
      switch ((raw as String? ?? '').toLowerCase()) {
        'synced' => SyncStatus.synced,
        'failed' => SyncStatus.failed,
        _ => SyncStatus.pending,
      };

  static String? _str(dynamic v) => v is String ? v : null;

  static double _double(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return 1;
  }

  static bool? _bool(dynamic v) {
    if (v is bool) return v;
    return null;
  }

  static DateTime? _dateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    // Duck-type Firestore Timestamp sin importar cloud_firestore.
    // Timestamp expone toDate() → DateTime; cualquier otro tipo lanzará
    // NoSuchMethodError que capturamos y devolvemos null.
    try {
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  /// Parsea fechas en formato `YYYY-MM-DD` usadas por el schema legacy.
  static DateTime? _dateFromDateString(String? s) {
    if (s == null) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${s}T00:00:00.000');
  }
}

// ── Datos extendidos ──────────────────────────────────────────────────────────

/// Campos presentes en Firestore que no tienen campo equivalente en
/// [TransactionEntity]. Se devuelven por separado desde el mapper
/// para que el repositorio decida cómo usarlos.
///
/// - [categoryId]: referencia a `users/{uid}/categories/{catId}`
/// - [isRecurring]: transacción recurrente (legacy `es_recurrente`)
/// - [profileId]: soporte multi-perfil (legacy `profile_id`)
class TransactionFirestoreExtras {
  final String? categoryId;
  final bool? isRecurring;
  final String? profileId;

  const TransactionFirestoreExtras({
    this.categoryId,
    this.isRecurring,
    this.profileId,
  });

  @override
  String toString() =>
      'TransactionFirestoreExtras('
      'categoryId: $categoryId, '
      'isRecurring: $isRecurring, '
      'profileId: $profileId)';
}
