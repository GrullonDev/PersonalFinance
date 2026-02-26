import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

abstract class SyncableModel extends SyncableEntity {
  const SyncableModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    super.deletedAt,
    super.syncStatus,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(), // Always update on write
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'deviceId': deviceId,
    'version': version + 1, // Increment version on write
  };

  // To be implemented by subclasses
  Map<String, dynamic> toJson();
}

DateTime dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  return DateTime.now();
}

dynamic timestampFromDateTime(DateTime? dateTime) =>
    dateTime != null ? Timestamp.fromDate(dateTime) : null;
