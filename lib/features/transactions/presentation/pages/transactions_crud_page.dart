import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart' as ew;
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:personal_finance/utils/widgets/empty_state.dart';

class TransactionsCrudPage extends StatelessWidget {
  const TransactionsCrudPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionsBloc>(
      create:
          (BuildContext context) =>
              TransactionsBloc(context.read())..add(TransactionsLoad()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Transacciones')),
        body: Column(
          children: <Widget>[
            _FiltersBar(),
            Expanded(
              child: BlocBuilder<TransactionsBloc, TransactionsState>(
                builder: (BuildContext context, TransactionsState state) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(child: AppLoadingWidget());
                  }
                  if (state.error != null && state.items.isEmpty) {
                    return Center(
                      child: ew.AppErrorWidget(message: state.error!),
                    );
                  }
                  if (state.items.isEmpty) {
                    return EmptyState(
                      title: 'Sin transacciones',
                      message:
                          'Agrega tu primera transacción para comenzar a llevar control.',
                      action: FilledButton.icon(
                        onPressed: () => _openDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar transacción'),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () async => context.read<TransactionsBloc>().add(
                          TransactionsLoad(),
                        ),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: state.items.length,
                      itemBuilder: (BuildContext context, int i) {
                        final TransactionBackend t = state.items[i];
                        final bool isIngreso =
                            t.tipo.toLowerCase() == 'ingreso';
                        final String amount =
                            '${isIngreso ? '+' : '-'}\$${t.montoAsDouble.toStringAsFixed(2)}';
                        return Dismissible(
                          key: ValueKey<String?>(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) => _confirmDelete(context),
                          onDismissed:
                              (_) => context.read<TransactionsBloc>().add(
                                TransactionDelete(t.id!),
                              ),
                          child: BlocBuilder<CategoriesBloc, CategoriesState>(
                            builder: (
                              BuildContext context,
                              CategoriesState cats,
                            ) {
                              final String catName =
                                  cats.items
                                      .firstWhere(
                                        (Category c) => c.id == t.categoriaId,
                                        orElse:
                                            () => Category(
                                              id: t.categoriaId,
                                              nombre: 'Cat #${t.categoriaId}',
                                              tipo: 'gasto',
                                            ),
                                      )
                                      .nombre;
                              return ListTile(
                                leading: Icon(
                                  isIngreso
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: isIngreso ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  t.descripcion.isEmpty
                                      ? '(sin descripción)'
                                      : t.descripcion,
                                ),
                                subtitle: Text(
                                  '${_fmt(t.fecha)}  ·  $catName${t.esRecurrente ? '  ·  Recurrente' : ''}',
                                ),
                                trailing: Text(
                                  amount,
                                  style: TextStyle(
                                    color:
                                        isIngreso ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _openDialog(context, tx: t),
                              );
                            },
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const Divider(height: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder:
              (BuildContext context) => FloatingActionButton.extended(
                onPressed: () => _openDialog(context),
                label: const Text('Nueva transacción'),
                icon: const Icon(Icons.add),
              ),
        ),
      ),
    );
  }

  Future<void> _openDialog(
    BuildContext context, {
    TransactionBackend? tx,
  }) async {
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    String tipo = tx?.tipo ?? 'ingreso';
    final TextEditingController amountCtrl = TextEditingController(
      text: tx?.montoAsDouble.toStringAsFixed(2) ?? '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: tx?.descripcion ?? '',
    );
    String? categoriaId = tx?.categoriaId;
    bool recurrente = tx?.esRecurrente ?? false;
    DateTime fecha = tx?.fecha ?? DateTime.now();

    await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(
              tx == null ? 'Crear transacción' : 'Editar transacción',
            ),
            content: Form(
              key: key,
              child: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // ... (Tipo dropdown remains same)
                      DropdownButtonFormField<String>(
                        initialValue: tipo,
                        decoration: const InputDecoration(labelText: 'Tipo'),
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
                        onChanged: (String? v) => tipo = v ?? 'ingreso',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Monto'),
                        validator:
                            (String? v) =>
                                (double.tryParse(v ?? '') ?? -1) <= 0
                                    ? 'Monto inválido'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<CategoriesBloc, CategoriesState>(
                        builder: (BuildContext context, CategoriesState cats) {
                          final List<DropdownMenuItem<String>> items =
                              cats.items
                                  .map(
                                    (Category c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.nombre),
                                    ),
                                  )
                                  .toList();
                          return DropdownButtonFormField<String>(
                            initialValue: categoriaId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: items,
                            onChanged: (String? v) => categoriaId = v,
                            validator:
                                (String? v) =>
                                    v == null
                                        ? 'Selecciona una categoría'
                                        : null,
                          );
                        },
                      ),
                      // ... (Rest of dialog)
                    ],
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  final TransactionsBloc bloc =
                      context.read<TransactionsBloc>();
                  final TransactionBackend payload = TransactionBackend(
                    id: tx?.id,
                    tipo: tipo,
                    monto: (double.parse(amountCtrl.text.trim())).toString(),
                    descripcion: descCtrl.text.trim(),
                    fecha: fecha,
                    categoriaId: categoriaId!,
                    esRecurrente: recurrente,
                  );
                  if (tx == null) {
                    bloc.add(TransactionCreate(payload));
                  } else {
                    bloc.add(TransactionUpdate(payload));
                  }
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
    // ...
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar esta transacción?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

class _FiltersBar extends StatefulWidget {
  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  DateTime? desde;
  DateTime? hasta;
  String? tipo;
  String? categoriaId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (BuildContext context, CategoriesState cats) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // ... (Date filters remain same)
              FilterChip(
                label: Text(desde == null ? 'Desde' : _fmt(desde!)),
                onSelected: (_) async {
                  final DateTime? d = await showDatePicker(
                    context: context,
                    initialDate: desde ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  setState(() => desde = d);
                  context.read<TransactionsBloc>().add(
                    TransactionsLoad(
                      desde: desde,
                      hasta: hasta,
                      categoriaId: categoriaId,
                      tipo: tipo,
                    ),
                  );
                },
              ),
              FilterChip(
                label: Text(hasta == null ? 'Hasta' : _fmt(hasta!)),
                onSelected: (_) async {
                  final DateTime? d = await showDatePicker(
                    context: context,
                    initialDate: hasta ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  setState(() => hasta = d);
                  context.read<TransactionsBloc>().add(
                    TransactionsLoad(
                      desde: desde,
                      hasta: hasta,
                      categoriaId: categoriaId,
                      tipo: tipo,
                    ),
                  );
                },
              ),
              DropdownButton<String>(
                value: tipo,
                hint: const Text('Tipo'),
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
                onChanged: (String? v) {
                  setState(() => tipo = v);
                  context.read<TransactionsBloc>().add(
                    TransactionsLoad(
                      desde: desde,
                      hasta: hasta,
                      categoriaId: categoriaId,
                      tipo: tipo,
                    ),
                  );
                },
              ),
              DropdownButton<String>(
                value: categoriaId,
                hint: const Text('Categoría'),
                items:
                    cats.items
                        .map(
                          (Category c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        )
                        .toList(),
                onChanged: (String? v) {
                  setState(() => categoriaId = v);
                  context.read<TransactionsBloc>().add(
                    TransactionsLoad(
                      desde: desde,
                      hasta: hasta,
                      categoriaId: categoriaId,
                      tipo: tipo,
                    ),
                  );
                },
              ),
              if (desde != null ||
                  hasta != null ||
                  tipo != null ||
                  categoriaId != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      desde = null;
                      hasta = null;
                      tipo = null;
                      categoriaId = null;
                    });
                    context.read<TransactionsBloc>().add(TransactionsLoad());
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
