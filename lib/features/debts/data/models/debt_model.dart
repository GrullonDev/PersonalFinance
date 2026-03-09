import 'package:personal_finance/core/data/models/syncable_model.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

class DebtModel extends SyncableModel {
  final String name;
  final double currentBalance;
  final double originalAmount;
  final double interestRate;
  final DateTime nextPaymentDate;
  final double minimumPayment;
  final String? profileId;

  const DebtModel({
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

  factory DebtModel.fromFirestore(Map<String, dynamic> json) => DebtModel(
    id: json['id'] as String,
    createdAt: dateTimeFromTimestamp(json['createdAt']),
    updatedAt: dateTimeFromTimestamp(json['updatedAt']),
    deletedAt:
        json['deletedAt'] != null
            ? dateTimeFromTimestamp(json['deletedAt'])
            : null,
    deviceId: json['deviceId'] as String? ?? 'unknown',
    version: json['version'] as int? ?? 1,
    name: json['name']?.toString() ?? '',
    currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
    originalAmount: double.tryParse(json['original_amount']?.toString() ?? '0') ?? 0.0,
    interestRate: double.tryParse(json['interest_rate']?.toString() ?? '0') ?? 0.0,
    nextPaymentDate:
        DateTime.tryParse(json['next_payment_date']?.toString() ?? '') ??
        DateTime.now(),
    minimumPayment: double.tryParse(json['minimum_payment']?.toString() ?? '0') ?? 0.0,
    profileId: json['profile_id']?.toString(),
  );

  @override
  Map<String, dynamic> toFirestore() => {
    ...super.toFirestore(),
    'name': name,
    'current_balance': currentBalance,
    'original_amount': originalAmount,
    'interest_rate': interestRate,
    'next_payment_date': nextPaymentDate.toIso8601String(),
    'minimum_payment': minimumPayment,
    'profile_id': profileId,
  };

  @override
  Map<String, dynamic> toJson() => toFirestore();

  factory DebtModel.fromEntity(Debt entity) => DebtModel(
    id: entity.id,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
    deviceId: entity.deviceId,
    version: entity.version,
    syncStatus: entity.syncStatus,
    name: entity.name,
    currentBalance: entity.currentBalance,
    originalAmount: entity.originalAmount,
    interestRate: entity.interestRate,
    nextPaymentDate: entity.nextPaymentDate,
    minimumPayment: entity.minimumPayment,
    profileId: entity.profileId,
  );

  Debt toEntity() => Debt(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    deviceId: deviceId,
    version: version,
    syncStatus: syncStatus,
    name: name,
    currentBalance: currentBalance,
    originalAmount: originalAmount,
    interestRate: interestRate,
    nextPaymentDate: nextPaymentDate,
    minimumPayment: minimumPayment,
    profileId: profileId,
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
