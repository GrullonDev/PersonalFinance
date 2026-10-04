import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/repositories/transaction_repository.dart';

class AiReportsPage extends StatefulWidget {
  const AiReportsPage({super.key});

  @override
  State<AiReportsPage> createState() => _AiReportsPageState();
}

class _AiReportsPageState extends State<AiReportsPage> {
  late DateTime _selectedMonth;
  bool _loadingData = false;
  bool _generatingReport = false;
  String? _reportText;
  String? _loadError;

  double _totalIncome = 0;
  double _totalExpenses = 0;
  int _expenseCount = 0;
  int _incomeCount = 0;
  bool _hasData = false;

  // Cached entities — evitan un segundo fetch al generar el reporte.
  List<ExpenseEntity> _expenses = [];
  List<IncomeEntity> _incomes = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadAndGenerate();
  }

  /// Carga datos del mes y genera el reporte automáticamente si hay información.
  Future<void> _loadAndGenerate() async {
    await _loadMonthData();
    if (mounted && _hasData) await _generateReport();
  }

  Future<void> _loadMonthData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
      _reportText = null;
      _totalIncome = 0;
      _totalExpenses = 0;
      _expenseCount = 0;
      _incomeCount = 0;
      _hasData = false;
      _expenses = [];
      _incomes = [];
    });

    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    final repo = GetIt.instance<TransactionRepository>();

    final expensesResult = await repo.getExpensesByPeriod(start, end);
    final incomesResult = await repo.getIncomesByPeriod(start, end);

    if (!mounted) return;

    expensesResult.fold(
      (_) => setState(() => _loadError = 'Error al cargar gastos'),
      (expenses) {
        _expenses = expenses;
        _totalExpenses = expenses.fold(0, (s, e) => s + e.amount);
        _expenseCount = expenses.length;
      },
    );

    incomesResult.fold(
      (_) {
        _incomes = [];
        _totalIncome = 0;
        _incomeCount = 0;
      },
      (incomes) {
        _incomes = incomes;
        _totalIncome = incomes.fold(0, (s, i) => s + i.amount);
        _incomeCount = incomes.length;
      },
    );

    setState(() {
      _hasData = _expenseCount > 0 || _incomeCount > 0;
      _loadingData = false;
    });
  }

  Future<void> _generateReport() async {
    if (!_hasData) return;
    setState(() => _generatingReport = true);

    final aiService = GetIt.instance<VertexAiService>();
    final monthLabel = DateFormat('MMMM yyyy', 'es').format(_selectedMonth);

    final report = await aiService.generateMonthlyReport(
      expenses: _expenses,
      incomes: _incomes,
      totalIncome: _totalIncome,
      totalExpenses: _totalExpenses,
      monthLabel: monthLabel,
    );

    if (!mounted) return;
    setState(() {
      _reportText = report;
      _generatingReport = false;
    });
  }

  void _previousMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _loadAndGenerate();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    _loadAndGenerate();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final balance = _totalIncome - _totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Reportes con IA'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MonthSelector(
              month: _selectedMonth,
              onPrevious: _previousMonth,
              onNext: _isCurrentMonth ? null : _nextMonth,
            ),
            const SizedBox(height: 16),
            if (_loadingData)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_loadError != null)
              _ErrorCard(message: _loadError!, onRetry: _loadAndGenerate)
            else ...[
              _SummaryRow(
                totalIncome: _totalIncome,
                totalExpenses: _totalExpenses,
                balance: balance,
              ),
              const SizedBox(height: 8),
              Text(
                '$_expenseCount gasto${_expenseCount != 1 ? "s" : ""} · $_incomeCount ingreso${_incomeCount != 1 ? "s" : ""}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_hasData)
                _EmptyDataCard(monthLabel: DateFormat('MMMM', 'es').format(_selectedMonth))
              else if (_generatingReport)
                const _GeneratingCard()
              else if (_reportText != null)
                _ReportCard(
                  reportText: _reportText!,
                  onRegenerate: _generateReport,
                )
              else
                // Fallback: la generación falló silenciosamente — ofrecer reintento.
                _RetryReportCard(onRetry: _generateReport),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Text(
          DateFormat('MMMM yyyy', 'es').format(month).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: onNext == null ? Colors.grey[400] : null,
          ),
          onPressed: onNext,
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  final double totalIncome;
  final double totalExpenses;
  final double balance;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _SummaryChip(label: 'Ingresos', amount: totalIncome, color: Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _SummaryChip(label: 'Gastos', amount: totalExpenses, color: Colors.red)),
      const SizedBox(width: 8),
      Expanded(child: _SummaryChip(label: 'Balance', amount: balance, color: balance >= 0 ? Colors.green : Colors.red)),
    ],
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            'Q${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

class _RetryReportCard extends StatelessWidget {
  const _RetryReportCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          const Text(
            'No se pudo generar el reporte',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica tu conexión e intenta de nuevo.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard();

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
    ),
    child: const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
          ),
          SizedBox(height: 20),
          Text(
            'Analizando tus finanzas...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'La IA está procesando tus transacciones y preparando tu reporte personalizado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.reportText, required this.onRegenerate});

  final String reportText;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          const Text(
            'Análisis generado por IA',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            reportText,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onRegenerate,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Regenerar reporte'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
      ),
    ],
  );
}

class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin datos en $monthLabel',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra ingresos y gastos para poder generar tu reporte con IA.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
