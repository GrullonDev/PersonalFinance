import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';

// Events
abstract class CategoriesEvent extends Equatable {
  @override
  List<Object?> get props => <Object?>[];
}

class CategoriesLoad extends CategoriesEvent {}

class CategoryCreate extends CategoriesEvent {
  CategoryCreate(this.nombre, this.tipo);
  final String nombre;
  final String tipo;
}

class CategoryUpdate extends CategoriesEvent {
  CategoryUpdate(this.id, this.nombre, this.tipo);
  final int id;
  final String nombre;
  final String tipo;
}

class CategoryDelete extends CategoriesEvent {
  CategoryDelete(this.id);
  final int id;
}

// State
class CategoriesState extends Equatable {
  const CategoriesState({
    this.loading = false,
    this.error,
    this.items = const <Category>[],
  });

  final bool loading;
  final String? error;
  final List<Category> items;

  CategoriesState copyWith({
    bool? loading,
    String? error,
    List<Category>? items,
  }) => CategoriesState(
    loading: loading ?? this.loading,
    error: error,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => <Object?>[loading, error, items];
}

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._repo) : super(const CategoriesState()) {
    on<CategoriesLoad>(_onLoad);
    on<CategoryCreate>(_onCreate);
    on<CategoryUpdate>(_onUpdate);
    on<CategoryDelete>(_onDelete);
  }

  final CategoryRepository _repo;

  Future<void> _onLoad(
    CategoriesLoad event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _repo.getCategories();
    result.fold(
      (l) => emit(state.copyWith(loading: false, error: l.message)),
      (r) => emit(state.copyWith(loading: false, items: r, error: null)),
    );
  }

  Future<void> _onCreate(
    CategoryCreate event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.createCategory(
      Category(nombre: event.nombre, tipo: event.tipo),
    );
    res.fold((l) => emit(state.copyWith(loading: false, error: l.message)), (
      created,
    ) {
      final List<Category> items = List<Category>.from(state.items)
        ..add(created);
      emit(state.copyWith(loading: false, items: items));
    });
  }

  Future<void> _onUpdate(
    CategoryUpdate event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.updateCategory(
      Category(id: event.id, nombre: event.nombre, tipo: event.tipo),
    );
    res.fold((l) => emit(state.copyWith(loading: false, error: l.message)), (
      updated,
    ) {
      final List<Category> items =
          state.items.map((c) => c.id == updated.id ? updated : c).toList();
      emit(state.copyWith(loading: false, items: items));
    });
  }

  Future<void> _onDelete(
    CategoryDelete event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    final res = await _repo.deleteCategory(event.id);
    res.fold((l) => emit(state.copyWith(loading: false, error: l.message)), (
      _,
    ) {
      final List<Category> items =
          state.items.where((c) => c.id != event.id).toList();
      emit(state.copyWith(loading: false, items: items));
    });
  }
}
