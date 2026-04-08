import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class QuickFinanceEvent extends Equatable {
  const QuickFinanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuickFinance extends QuickFinanceEvent {}

class AddTransactionEvent extends QuickFinanceEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);
  
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends QuickFinanceEvent {
  final String id;
  const DeleteTransactionEvent(this.id);
  
  @override
  List<Object?> get props => [id];
}

class SyncTransactionsEvent extends QuickFinanceEvent {}
