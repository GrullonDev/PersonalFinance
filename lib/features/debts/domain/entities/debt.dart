import 'package:personal_finance/core/domain/entities/syncable_entity.dart';

class Debt extends SyncableEntity {
  final String name;
  final double currentBalance;
  final double originalAmount;
  final double interestRate;
  final DateTime nextPaymentDate;
  final double minimumPayment;
  final String? profileId;

  const Debt({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required super.deviceId,
    required super.version,
    required this.name,
    required this.currentBalance,
    required this.originalAmount,
    required this.interestRate,
    required this.nextPaymentDate,
    required this.minimumPayment,
    super.deletedAt,
    super.syncStatus,
    this.profileId,
  });

  Debt copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    int? version,
    String? name,
    double? currentBalance,
    double? originalAmount,
    double? interestRate,
    DateTime? nextPaymentDate,
    double? minimumPayment,
    DateTime? deletedAt,
    String? profileId,
  }) => Debt(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    version: version ?? this.version,
    name: name ?? this.name,
    currentBalance: currentBalance ?? this.currentBalance,
    originalAmount: originalAmount ?? this.originalAmount,
    interestRate: interestRate ?? this.interestRate,
    nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
    minimumPayment: minimumPayment ?? this.minimumPayment,
    deletedAt: deletedAt ?? this.deletedAt,
    profileId: profileId ?? this.profileId,
  );

  @override
  List<Object?> get props => [
    ...super.props,
    name,
    currentBalance,
    originalAmount,
    interestRate,
    nextPaymentDate,
    minimumPayment,
    profileId,
  ];
}
