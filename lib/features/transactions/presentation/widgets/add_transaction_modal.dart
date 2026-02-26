import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/categories/presentation/bloc/categories_bloc.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:personal_finance/utils/responsive.dart';
import 'package:personal_finance/core/services/device_service.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:intl/intl.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _tipo = 'gasto';
  String? _categoriaId;
  DateTime _fecha = DateTime.now();
  bool _recurrente = false;
  String _frecuencia = 'mensual';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 500,
            maxHeight: mq.size.height * 0.9, // Avoid full screen
          ),
          padding: EdgeInsets.only(
            bottom: mq.viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          decoration:
              context.isMobile
                  ? null
                  : BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = (constraints.maxWidth - 8) / 2;
                      return Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              left: _tipo == 'gasto' ? 0 : itemWidth,
                              top: 0,
                              bottom: 0,
                              width: itemWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      _tipo == 'gasto'
                                          ? const Color(
                                            0xFFFF5252,
                                          ).withValues(alpha: 0.15)
                                          : const Color(
                                            0xFF4CAF50,
                                          ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _tipo = 'gasto');
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              _tipo == 'gasto'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              _tipo == 'gasto'
                                                  ? const Color(0xFFD32F2F)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                        ),
                                        child: const Text('Gasto'),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _tipo = 'ingreso');
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              _tipo == 'ingreso'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              _tipo == 'ingreso'
                                                  ? const Color(0xFF388E3C)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                        ),
                                        child: const Text('Ingreso'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Monto Enorme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color:
                              _tipo == 'gasto'
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF388E3C),
                        ),
                        child: const Text('\$'),
                      ),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color:
                                _tipo == 'gasto'
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFF388E3C),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Monto requerido';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child:
                        _tipo == 'gasto'
                            ? Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Text(
                                'Impactará tu presupuesto de ${toBeginningOfSentenceCase(DateFormat.MMMM('es').format(_fecha))}',
                                style: TextStyle(
                                  color: const Color(
                                    0xFFD32F2F,
                                  ).withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  BlocBuilder<CategoriesBloc, CategoriesState>(
                    builder:
                        (
                          BuildContext context,
                          CategoriesState cats,
                        ) => DropdownButtonFormField<String>(
                          initialValue: _categoriaId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          hint: const Text('Selecciona una categoría'),
                          items:
                              cats.items
                                  .map(
                                    (Category c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.nombre),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (String? v) => setState(() => _categoriaId = v),
                          validator:
                              (String? v) =>
                                  v == null ? 'Selecciona una categoría' : null,
                        ),
                  ),
                  const SizedBox(height: 24),

                  _DatePickerField(
                    selectedDate: _fecha,
                    onDateSelected: (DateTime d) => setState(() => _fecha = d),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Transacción recurrente',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          value: _recurrente,
                          activeThumbColor:
                              Theme.of(context).colorScheme.primary,
                          onChanged: (bool value) {
                            HapticFeedback.lightImpact();
                            setState(() => _recurrente = value);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child:
                              _recurrente
                                  ? Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _frecuencia,
                                      decoration: InputDecoration(
                                        labelText: 'Repetir',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'mensual',
                                          child: Text('Mensual'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'quincenal',
                                          child: Text('Quincenal'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'semanal',
                                          child: Text('Semanal'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _frecuencia = val);
                                        }
                                      },
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        HapticFeedback.heavyImpact();
                        return;
                      }
                      HapticFeedback.lightImpact();

                      final TransactionsBloc bloc =
                          context.read<TransactionsBloc>();
                      final now = DateTime.now();
                      final deviceId = getIt<DeviceService>().deviceId;
                      final TransactionBackend payload = TransactionBackend(
                        id: 'tx_${now.microsecondsSinceEpoch}',
                        createdAt: now,
                        updatedAt: now,
                        deviceId: deviceId,
                        version: 1,
                        tipo: _tipo,
                        monto:
                            double.parse(
                              _amountController.text.trim(),
                            ).toString(),
                        descripcion: _descriptionController.text.trim(),
                        fecha: _fecha,
                        categoriaId: _categoriaId ?? '',
                        esRecurrente: _recurrente,
                      );
                      bloc.add(TransactionCreate(payload));

                      HapticFeedback.mediumImpact();
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('¡Transacción agregada con éxito!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Guardar Transacción',
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Categories are managed by the global CategoriesBloc

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Fecha',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      child: Text(
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
      ),
    ),
  );
}
