import 'package:equatable/equatable.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

abstract class DebtsEvent extends Equatable {
  const DebtsEvent();

  @override
  List<Object> get props => [];
}

class DebtsLoad extends DebtsEvent {}

class DebtCreate extends DebtsEvent {
  final Debt debt;

  const DebtCreate(this.debt);

  @override
  List<Object> get props => [debt];
}

class DebtUpdate extends DebtsEvent {
  final Debt debt;

  const DebtUpdate(this.debt);

  @override
  List<Object> get props => [debt];
}

class DebtDelete extends DebtsEvent {
  final String debtId;

  const DebtDelete(this.debtId);

  @override
  List<Object> get props => [debtId];
}
