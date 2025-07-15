import 'package:flutter/material.dart';

import 'package:personal_finance/features/dashboard/widgets/add_transaction_modal.dart';
import 'package:personal_finance/utils/app_localization.dart';

/// Botón flotante para agregar nuevas transacciones (gastos o ingresos).
/// 
/// Muestra un modal bottom sheet cuando se presiona, permitiendo al usuario
/// elegir entre agregar un gasto o un ingreso.
class AddTransactionButton extends StatelessWidget {
  /// Crea un botón flotante para agregar transacciones.
  const AddTransactionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext context) => const AddTransactionModal(),
        ),
    icon: const Icon(Icons.add),
    label: Text(AppLocalizations.of(context)!.add),
  );
}
