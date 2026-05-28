enum SyncStatus { synchronized, pending, error, conflict }

extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.synchronized:
        return 'Sincronizado';
      case SyncStatus.pending:
        return 'Pendiente';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.conflict:
        return 'Conflicto';
    }
  }
}
