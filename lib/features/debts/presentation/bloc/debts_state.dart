import 'package:equatable/equatable.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';

class DebtsState extends Equatable {
  final List<Debt> items;
  final bool loading;
  final String? error;

  const DebtsState({this.items = const [], this.loading = false, this.error});

  DebtsState copyWith({List<Debt>? items, bool? loading, String? error}) =>
      DebtsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error,
      );

  @override
  List<Object?> get props => [items, loading, error];
}
