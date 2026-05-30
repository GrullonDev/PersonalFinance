import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';

enum _ExportFormat { csv, txt }

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _to = DateTime.now();
  _ExportFormat _format = _ExportFormat.csv;
  bool _exporting = false;
  String? _lastExportPath;

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
      helpText: 'Fecha de inicio',
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now(),
      helpText: 'Fecha de fin',
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _lastExportPath = null;
    });

    try {
      final repo = GetIt.instance<TransactionRepository>();
      final end = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);

      final expensesResult = await repo.getExpensesByPeriod(_from, end);
      final incomesResult = await repo.getIncomesByPeriod(_from, end);

      final expenses = expensesResult.fold<List<ExpenseEntity>>((_) => [], (e) => e);
      final incomes = incomesResult.fold<List<IncomeEntity>>((_) => [], (i) => i);

      if (expenses.isEmpty && incomes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay transacciones en el rango seleccionado.')),
        );
        return;
      }

      final dateRange =
          '${DateFormat('dd-MM-yyyy').format(_from)}_al_${DateFormat('dd-MM-yyyy').format(_to)}';
      final ext = _format == _ExportFormat.csv ? 'csv' : 'txt';
      final fileName = 'finanzas_$dateRange.$ext';

      final content = _format == _ExportFormat.csv
          ? _buildCsv(expenses, incomes)
          : _buildTxt(expenses, incomes);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      if (!mounted) return;
      setState(() => _lastExportPath = file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _buildCsv(List<ExpenseEntity> expenses, List<IncomeEntity> incomes) {
    final buf = StringBuffer();
    buf.writeln('Tipo,Fecha,Descripción,Categoría/Fuente,Monto (Q)');
    for (final e in expenses) {
      final fecha = DateFormat('dd/MM/yyyy').format(e.date);
      final titulo = e.title.replaceAll(',', ' ');
      final cat = e.category.replaceAll(',', ' ');
      buf.writeln('Gasto,$fecha,$titulo,$cat,${e.amount.toStringAsFixed(2)}');
    }
    for (final i in incomes) {
      final fecha = DateFormat('dd/MM/yyyy').format(i.date);
      final titulo = i.title.replaceAll(',', ' ');
      final fuente = i.source.replaceAll(',', ' ');
      buf.writeln('Ingreso,$fecha,$titulo,$fuente,${i.amount.toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  String _buildTxt(List<ExpenseEntity> expenses, List<IncomeEntity> incomes) {
    final buf = StringBuffer();
    final fmt = DateFormat('dd/MM/yyyy');
    final fromLabel = DateFormat('dd/MM/yyyy').format(_from);
    final toLabel = DateFormat('dd/MM/yyyy').format(_to);

    buf.writeln('REPORTE FINANCIERO');
    buf.writeln('Período: $fromLabel – $toLabel');
    buf.writeln('=' * 40);

    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final totalIncomes = incomes.fold<double>(0, (s, i) => s + i.amount);

    buf.writeln('\nINGRESOS (${incomes.length})');
    buf.writeln('-' * 30);
    for (final i in incomes) {
      buf.writeln('${fmt.format(i.date)}  ${i.title}  Q${i.amount.toStringAsFixed(2)}');
    }
    buf.writeln('Total ingresos: Q${totalIncomes.toStringAsFixed(2)}');

    buf.writeln('\nGASTOS (${expenses.length})');
    buf.writeln('-' * 30);
    for (final e in expenses) {
      buf.writeln('${fmt.format(e.date)}  ${e.title}  [${e.category}]  Q${e.amount.toStringAsFixed(2)}');
    }
    buf.writeln('Total gastos: Q${totalExpenses.toStringAsFixed(2)}');

    buf.writeln('\n${'=' * 40}');
    buf.writeln('BALANCE: Q${(totalIncomes - totalExpenses).toStringAsFixed(2)}');

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Exportar datos'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecciona el rango de fechas y formato para exportar tus transacciones.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'RANGO DE FECHAS'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateCard(
                  label: 'Desde',
                  date: fmt.format(_from),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickFromDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateCard(
                  label: 'Hasta',
                  date: fmt.format(_to),
                  icon: Icons.event_outlined,
                  onTap: _pickToDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'FORMATO'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FormatCard(
                  label: 'CSV',
                  description: 'Compatible con Excel y Google Sheets',
                  icon: Icons.table_chart_outlined,
                  selected: _format == _ExportFormat.csv,
                  onTap: () => setState(() => _format = _ExportFormat.csv),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormatCard(
                  label: 'TXT',
                  description: 'Resumen legible en texto plano',
                  icon: Icons.description_outlined,
                  selected: _format == _ExportFormat.txt,
                  onTap: () => setState(() => _format = _ExportFormat.txt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(_exporting ? 'Exportando...' : 'Exportar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF6366F1),
            ),
          ),
          if (_lastExportPath != null) ...[
            const SizedBox(height: 20),
            _SuccessCard(
              filePath: _lastExportPath!,
              onCopyPath: () {
                Clipboard.setData(ClipboardData(text: _lastExportPath!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta copiada al portapapeles')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border.all(
          color: selected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.3),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? const Color(0xFF6366F1) : Colors.grey,
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? const Color(0xFF6366F1) : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.filePath, required this.onCopyPath});

  final String filePath;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Archivo exportado',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Guardado en Documentos de la app',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onCopyPath,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar ruta'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
