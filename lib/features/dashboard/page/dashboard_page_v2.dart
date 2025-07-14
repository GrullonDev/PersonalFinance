import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic_v2.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_layout.dart';
import 'package:personal_finance/utils/widgets/error_widget.dart';
import 'package:personal_finance/utils/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

/// Página del dashboard que usa la nueva arquitectura limpia
class DashboardPageV2 extends StatefulWidget {
  const DashboardPageV2({super.key});

  @override
  State<DashboardPageV2> createState() => _DashboardPageV2State();
}

class _DashboardPageV2State extends State<DashboardPageV2> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardLogicV2>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<DashboardLogicV2>(
      builder: (BuildContext context, DashboardLogicV2 logic, _) {
        // Mostrar loading si está cargando
        if (logic.isLoading) {
          return const Scaffold(
            body: AppLoadingWidget(
              message: 'Cargando datos del dashboard...',
            ),
          );
        }

        // Mostrar error si hay error
        if (logic.error != null) {
          return Scaffold(
            body: AppErrorWidget(
              message: logic.error!,
              onRetry: () => logic.loadDashboardData(),
            ),
          );
        }

        // Mostrar dashboard normal
        return const Scaffold(
          body: DashboardLayout(),
        );
      },
    );
} 