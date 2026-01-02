import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<CategoriesBloc>(
    create:
        (_) =>
            CategoriesBloc(getIt<CategoryRepository>())..add(CategoriesLoad()),
    child: Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (BuildContext context, CategoriesState state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: AppLoadingWidget());
          }
          if (state.error != null && state.items.isEmpty) {
            return Center(child: ew.AppErrorWidget(message: state.error!));
          }
          if (state.items.isEmpty) {
            return EmptyState(
              title: 'Sin categorías',
              message: 'Crea tus categorías para organizar mejor tus finanzas.',
              action: FilledButton.icon(
                onPressed: () => _openCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh:
                () async =>
                    context.read<CategoriesBloc>().add(CategoriesLoad()),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length,
              itemBuilder: (BuildContext context, int index) {
                final Category category = state.items[index];
                return Dismissible(
                  key: ValueKey<String?>(category.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss:
                      (DismissDirection d) async =>
                          await _confirmDelete(context),
                  onDismissed:
                      (_) => context.read<CategoriesBloc>().add(
                        CategoryDelete(category.id!),
                      ),
                  child: ListTile(
                    leading: Icon(
                      category.tipo.toLowerCase() == 'ingreso'
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color:
                          category.tipo.toLowerCase() == 'ingreso'
                              ? Colors.green
                              : Colors.red,
                    ),
                    title: Text(category.nombre),
                    subtitle: Text('Tipo: ${category.tipo}'),
                    onTap:
                        () => _openCategoryDialog(context, category: category),
                  ),
                );
              },
              separatorBuilder:
                  (BuildContext context, int _) => const Divider(height: 1),
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder:
            (BuildContext context) => FloatingActionButton.extended(
              onPressed: () => _openCategoryDialog(context),
              label: const Text('Nueva categoría'),
              icon: const Icon(Icons.add),
            ),
      ),
    ),
  );

  Future<void> _openCategoryDialog(
    BuildContext context, {
    Category? category,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: category?.nombre ?? '',
    );

    // Normalizar el tipo: convertir 'gasto' a 'egreso' para compatibilidad
    String tipo = category?.tipo ?? 'ingreso';
    if (tipo.toLowerCase() == 'gasto') {
      tipo = 'egreso';
    }

    // Capturar el bloc ANTES de abrir el diálogo para evitar problemas de contexto
    final CategoriesBloc bloc = context.read<CategoriesBloc>();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder:
                (BuildContext context, StateSetter setState) => AlertDialog(
                  title: Text(
                    category == null ? 'Crear categoría' : 'Editar categoría',
                  ),
                  content: Form(
                    key: formKey,
                    child: SizedBox(
                      width: 340,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                            ),
                            validator:
                                (String? v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Ingrese un nombre'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: tipo,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                value: 'ingreso',
                                child: Text('Ingreso'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'egreso',
                                child: Text('Egreso'),
                              ),
                            ],
                            onChanged: (String? v) {
                              setState(() {
                                tipo = v ?? 'ingreso';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (category == null) {
                          bloc.add(CategoryCreate(nameCtrl.text.trim(), tipo));
                        } else {
                          bloc.add(
                            CategoryUpdate(
                              category.id!,
                              nameCtrl.text.trim(),
                              tipo,
                            ),
                          );
                        }
                        Navigator.pop(context, true);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null ? 'Categoría creada' : 'Categoría actualizada',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Eliminar categoría'),
            content: const Text(
              '¿Deseas eliminar esta categoría? Esta acción no se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    return confirm ?? false;
  }
}
