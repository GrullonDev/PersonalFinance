import 'package:equatable/equatable.dart';
import 'package:personal_finance/core/domain/entities/sync_status.dart';

abstract class SyncableEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  final int version;
  final SyncStatus syncStatus;

  const SyncableEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    required this.version,
    this.deletedAt,
    this.syncStatus = SyncStatus.synchronized,
  });

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    deviceId,
    version,
    syncStatus,
  ];
}
