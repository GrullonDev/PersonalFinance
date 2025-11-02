import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:personal_finance/features/accounts/domain/entities/account.dart';

part 'account_model.g.dart';

@JsonSerializable()
class AccountModel extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String type; // 'savings', 'checking', 'credit', 'investment', etc.
  final String? icon;
  final String? color;

  const AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.icon,
    this.color,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccountModelToJson(this);

  factory AccountModel.fromEntity(Account account) => AccountModel(
    id: account.id,
    name: account.name,
    balance: account.balance,
    type: account.type,
    icon: account.icon,
    color: account.color,
  );

  Account toEntity() => Account(
    id: id,
    name: name,
    balance: balance,
    type: type,
    icon: icon,
    color: color,
  );

  @override
  List<Object?> get props => <Object?>[id, name, balance, type, icon, color];
}
