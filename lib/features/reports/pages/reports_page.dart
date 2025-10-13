import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';
import 'package:personal_finance/features/reports/logic/reports_logic.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Widget _buildSummary(String title, double amount, Color color) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ReportsLogic()..loadReportData(),
    child: Consumer<ReportsLogic>(
      builder: (BuildContext context, ReportsLogic logic, _) {
        if (logic.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (logic.error != null) {
          return Center(child: Text(logic.error!));
        }

        if (!logic.hasData) {
          return const Center(child: Text('Sin datos para mostrar'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildSummary(
                      'Ingresos',
                      logic.totalIncomes,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummary(
                      'Gastos',
                      logic.totalExpenses,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Distribución de gastos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: SfCircularChart(
                          series: <CircularSeries<ChartData, String>>[
                            DoughnutSeries<ChartData, String>(
                              dataSource: logic.chartData,
                              xValueMapper: (ChartData d, _) => d.category,
                              yValueMapper: (ChartData d, _) => d.amount,
                              pointColorMapper: (ChartData d, _) => d.color,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
