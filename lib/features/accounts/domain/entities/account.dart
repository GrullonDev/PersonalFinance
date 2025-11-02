import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String type; // 'savings', 'checking', 'credit', 'investment', etc.
  final String? icon;
  final String? color;

  const Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => <Object?>[id, name, balance, type, icon, color];
}
