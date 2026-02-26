import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/utils/responsive.dart';

import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';
import 'package:personal_finance/utils/premium_modals.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Categorías'),
      actions: [
        if (!context.isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva categoría'),
            ),
          ),
      ],
    ),
    body: Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.isMobile ? double.infinity : 700,
        ),
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
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
                message:
                    'Crea tus categorías para organizar mejor tus finanzas.',
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
                          CategoryDelete(category.id),
                        ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (category.tipo.toLowerCase() == 'ingreso'
                                    ? Colors.green
                                    : Colors.red)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.tipo.toLowerCase() == 'ingreso'
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color:
                                category.tipo.toLowerCase() == 'ingreso'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                        title: Text(
                          category.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (category.tipo.toLowerCase() ==
                                              'ingreso'
                                          ? Colors.green
                                          : Colors.red)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category.tipo.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        category.tipo.toLowerCase() == 'ingreso'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        onTap:
                            () => _openCategoryDialog(
                              context,
                              category: category,
                            ),
                      ),
                    ),
                  );
                },
                separatorBuilder:
                    (BuildContext context, int _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
              ),
            );
          },
        ),
      ),
    ),
    bottomNavigationBar: Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withBlue(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _openCategoryDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Nueva categoría',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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

    final bool? saved = await showPremiumDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder:
                (BuildContext context, StateSetter setState) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  title: Text(
                    category == null ? 'Crear categoría' : 'Editar categoría',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                            decoration: InputDecoration(
                              labelText: 'Nombre de categoría',
                              prefixIcon: const Icon(
                                Icons.label_outline_rounded,
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator:
                                (String? v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Ingrese un nombre'
                                        : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => tipo = 'ingreso'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          tipo == 'ingreso'
                                              ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            tipo == 'ingreso'
                                                ? Colors.green
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.trending_up_rounded,
                                          color:
                                              tipo == 'ingreso'
                                                  ? Colors.green
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ingreso',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                tipo == 'ingreso'
                                                    ? Colors.green
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => tipo = 'egreso'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          tipo == 'egreso'
                                              ? Colors.red.withValues(
                                                alpha: 0.1,
                                              )
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            tipo == 'egreso'
                                                ? Colors.red
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.trending_down_rounded,
                                          color:
                                              tipo == 'egreso'
                                                  ? Colors.red
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Gasto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                tipo == 'egreso'
                                                    ? Colors.red
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (category == null) {
                          bloc.add(CategoryCreate(nameCtrl.text.trim(), tipo));
                        } else {
                          bloc.add(
                            CategoryUpdate(
                              category.id,
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
