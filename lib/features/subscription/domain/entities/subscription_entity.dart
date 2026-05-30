import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PlanTier {
  free,
  pro;

  bool get isPro => this == pro;

  String get displayName => switch (this) {
    PlanTier.free => 'Free',
    PlanTier.pro => 'Pro',
  };

  String get productId => switch (this) {
    PlanTier.free => '',
    PlanTier.pro => 'pf_pro_monthly',
  };
}

enum SubscriptionStatus {
  active,
  expired,
  canceled,
  trial;

  bool get isValid => this == active || this == trial;
}

enum PlanFeature {
  unlimitedBudgets,
  unlimitedGoals,
  unlimitedAccounts,
  aiChat,
  monthlyAiReports,
  predictiveAlerts,
  exportCsvPdf,
  recurringTransactions,
  premiumThemes,
  homeWidget,
}

class SubscriptionEntity extends Equatable {
  final PlanTier tier;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final String? orderId;
  final String? productId;

  const SubscriptionEntity({
    required this.tier,
    required this.status,
    this.expiresAt,
    this.purchasedAt,
    this.orderId,
    this.productId,
  });

  bool get isPremium => tier.isPro && status.isValid;

  static const SubscriptionEntity free = SubscriptionEntity(
    tier: PlanTier.free,
    status: SubscriptionStatus.active,
  );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory SubscriptionEntity.fromMap(Map<String, dynamic> map) =>
      SubscriptionEntity(
        tier: PlanTier.values.firstWhere(
          (e) => e.name == (map['tier'] as String? ?? 'free'),
          orElse: () => PlanTier.free,
        ),
        status: SubscriptionStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'active'),
          orElse: () => SubscriptionStatus.active,
        ),
        expiresAt: _parseDate(map['expiresAt']),
        purchasedAt: _parseDate(map['purchasedAt']),
        orderId: map['orderId'] as String?,
        productId: map['productId'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'tier': tier.name,
    'status': status.name,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'purchasedAt':
        purchasedAt != null ? Timestamp.fromDate(purchasedAt!) : null,
    'orderId': orderId,
    'productId': productId,
  };

  SubscriptionEntity copyWith({
    PlanTier? tier,
    SubscriptionStatus? status,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    String? orderId,
    String? productId,
  }) => SubscriptionEntity(
    tier: tier ?? this.tier,
    status: status ?? this.status,
    expiresAt: expiresAt ?? this.expiresAt,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
  );

  @override
  List<Object?> get props => [
    tier,
    status,
    expiresAt,
    purchasedAt,
    orderId,
    productId,
  ];
}
