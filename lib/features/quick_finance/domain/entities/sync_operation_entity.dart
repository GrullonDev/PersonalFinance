import 'package:equatable/equatable.dart';
import 'package:personal_finance/core/constants/enums.dart';

class SyncOperationEntity extends Equatable {
  final String id;
  final String transactionId;
  final SyncAction action;
  final DateTime createdAt;
  final bool processed;

  const SyncOperationEntity({
    required this.id,
    required this.transactionId,
    required this.action,
    required this.createdAt,
    required this.processed,
  });

  @override
  List<Object?> get props => [id, transactionId, action, createdAt, processed];
}
