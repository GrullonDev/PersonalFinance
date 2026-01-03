import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';

import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';

class QuickAddCategory extends StatelessWidget {
  const QuickAddCategory({super.key});

  @override
  Widget build(BuildContext context) => const _QuickAddCategoryContent();
}

class _QuickAddCategoryContent extends StatefulWidget {
  const _QuickAddCategoryContent();

  @override
  State<_QuickAddCategoryContent> createState() =>
      _QuickAddCategoryContentState();
}

class _QuickAddCategoryContentState extends State<_QuickAddCategoryContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  String _tipo = 'ingreso';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.category_outlined),
              const SizedBox(width: 8),
              Text(
                'Agregar categoría rápida',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/categories'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool vertical = constraints.maxWidth < 520;
                if (!vertical) {
                  // Horizontal layout (safe to use Expanded for widths)
                  return Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la categoría',
                            isDense: true,
                          ),
                          validator:
                              (String? v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Ingrese un nombre'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipo,
                          isExpanded: true,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'ingreso',
                              child: Text('Ingreso'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'gasto',
                              child: Text('Gasto'),
                            ),
                          ],
                          onChanged:
                              (String? v) =>
                                  setState(() => _tipo = v ?? 'ingreso'),
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      BlocConsumer<CategoriesBloc, CategoriesState>(
                        listener: (
                          BuildContext context,
                          CategoriesState state,
                        ) {
                          if (!state.loading && state.error == null) {
                            _nameCtrl.clear();
                          }
                          if (state.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.error!)),
                            );
                          }
                        },
                        builder:
                            (BuildContext context, CategoriesState state) =>
                                SizedBox(
                                  width: 120,
                                  child: FilledButton.icon(
                                    onPressed:
                                        state.loading
                                            ? null
                                            : () {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              context
                                                  .read<CategoriesBloc>()
                                                  .add(
                                                    CategoryCreate(
                                                      _nameCtrl.text.trim(),
                                                      _tipo,
                                                    ),
                                                  );
                                            },
                                    icon:
                                        state.loading
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(Icons.add),
                                    label: const Text('Agregar'),
                                  ),
                                ),
                      ),
                    ],
                  );
                }

                // Vertical layout (no Expanded in unbounded height)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la categoría',
                        isDense: true,
                      ),
                      validator:
                          (String? v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Ingrese un nombre'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      isExpanded: true,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'ingreso',
                          child: Text('Ingreso'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'gasto',
                          child: Text('Gasto'),
                        ),
                      ],
                      onChanged:
                          (String? v) => setState(() => _tipo = v ?? 'ingreso'),
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocConsumer<CategoriesBloc, CategoriesState>(
                      listener: (BuildContext context, CategoriesState state) {
                        if (!state.loading && state.error == null) {
                          _nameCtrl.clear();
                        }
                        if (state.error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(state.error!)));
                        }
                      },
                      builder:
                          (BuildContext context, CategoriesState state) =>
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      state.loading
                                          ? null
                                          : () {
                                            if (!_formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            context.read<CategoriesBloc>().add(
                                              CategoryCreate(
                                                _nameCtrl.text.trim(),
                                                _tipo,
                                              ),
                                            );
                                          },
                                  icon:
                                      state.loading
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.add),
                                  label: const Text('Agregar'),
                                ),
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (BuildContext context, CategoriesState state) {
              if (state.items.isEmpty) {
                return const SizedBox.shrink();
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    state.items
                        .map(
                          (Category c) => Chip(
                            label: Text(c.nombre),
                            avatar: Icon(
                              c.tipo.toLowerCase() == 'ingreso'
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color:
                                  c.tipo.toLowerCase() == 'ingreso'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}
