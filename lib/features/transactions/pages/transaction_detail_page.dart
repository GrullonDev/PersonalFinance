import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/transactions/logic/transaction_detail_logic.dart';
import 'package:personal_finance/features/transactions/models/transaction_detail.dart';
import 'package:provider/provider.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionDetail transaction;

  const TransactionDetailPage({required this.transaction, super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<TransactionDetailLogic>(
    create: (_) => TransactionDetailLogic(transaction: transaction),
    child: const _TransactionDetailView(),
  );
}

class _TransactionDetailView extends StatelessWidget {
  const _TransactionDetailView();

  @override
  Widget build(BuildContext context) {
    final TransactionDetailLogic logic = Provider.of<TransactionDetailLogic>(
      context,
    );
    final TransactionDetail transaction = logic.transaction;
    final Color amountColor = transaction.isExpense ? Colors.red : Colors.green;
    final DateFormat dateFormatter = DateFormat("dd 'de' MMMM, yyyy", 'es');
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'es');
    final NumberFormat currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Transacción',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Información principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(transaction.amount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Categoría', transaction.category),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Fecha',
                      dateFormatter.format(transaction.date),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Hora',
                      timeFormatter.format(transaction.date),
                    ),
                    if (transaction.notes?.isNotEmpty ?? false) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildDetailRow('Notas', transaction.notes!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sección de división
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: logic.toggleExpanded,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Dividir Transacción',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            logic.isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                    if (logic.isExpanded) ...<Widget>[
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no hay divisiones',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => logic.showFiltersModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Añadir división'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sección de recibo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Recibo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (logic.receiptImagePath != null)
                      GestureDetector(
                        onTap: () => logic.previewReceipt(context),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(logic.receiptImagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toca para adjuntar una imagen del recibo de esta transacción.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => logic.pickReceiptImage(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: Text(
                        logic.receiptImagePath == null ? 'Adjuntar' : 'Cambiar',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ],
  );
}
