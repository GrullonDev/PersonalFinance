import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:personal_finance/features/transactions/models/transaction_detail.dart';

class TransactionDetailPage extends StatefulWidget {
  final TransactionDetail transaction;

  const TransactionDetailPage({required this.transaction, super.key});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  String? _receiptImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _receiptImagePath = widget.transaction.receiptImagePath;
  }

  Future<void> _pickReceiptImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImagePath = image.path;
        });

        // Aquí puedes guardar la ruta en tu base de datos
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recibo adjuntado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewReceiptImage() async {
    if (_receiptImagePath != null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) =>
                  _ReceiptImageViewer(imagePath: _receiptImagePath!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color amountColor =
        widget.transaction.isExpense ? Colors.red : Colors.green;
    final IconData categoryIcon = _getCategoryIcon(widget.transaction.category);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Detalle de Transacción',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header Card compacto
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: amountColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: amountColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.transaction.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat("d 'de' MMMM, yyyy", 'es')
                              .format(widget.transaction.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 1),

            // Monto más compacto
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Text(
                '${widget.transaction.isExpense ? '-' : '+'}\$${widget.transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ),

            const SizedBox(height: 1),

            // Detalles compactos
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  _buildCompactDetailRow('Categoría', widget.transaction.category),
                  const SizedBox(height: 12),
                  _buildCompactDetailRow(
                    'Fecha',
                    DateFormat("d 'de' MMMM, yyyy", 'es')
                        .format(widget.transaction.date),
                  ),
                  const SizedBox(height: 12),
                  _buildCompactDetailRow(
                    'Hora',
                    DateFormat('h:mm a', 'es').format(widget.transaction.date),
                  ),
                  if (widget.transaction.notes != null &&
                      widget.transaction.notes!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    _buildCompactDetailRow('Notas', widget.transaction.notes!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sección Dividir Transacción (solo para gastos)
            if (widget.transaction.isExpense) ...<Widget>[
              _buildSplitTransactionSection(),
              const SizedBox(height: 12),
            ],

            // Sección de Recibo (solo para gastos)
            if (widget.transaction.isExpense) ...<Widget>[
              _buildReceiptSection(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _buildSplitTransactionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.call_split, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dividir Transacción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Asigna partes de esta transacción a diferentes categorías o presupuestos',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Mostrar diálogo para dividir transacción
              _showSplitDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Añadir división',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Recibo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: _receiptImagePath != null
                ? _buildReceiptPreview()
                : _buildAddReceiptButton(),
          ),
        ],
      ),
    );
  }

  void _showSplitDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Dividir Transacción'),
        content: const Text(
          'Esta funcionalidad te permitirá dividir esta transacción en múltiples categorías.\n\nPróximamente disponible.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReceiptButton() => Column(
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.receipt_long, color: Colors.blue, size: 40),
      ),
      const SizedBox(height: 16),
      const Text(
        'Adjuntar Recibo',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Toca para adjuntar una imagen del recibo de\nesta transacción.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _pickReceiptImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Adjuntar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );

  Widget _buildReceiptPreview() => Column(
    children: <Widget>[
      GestureDetector(
        onTap: _viewReceiptImage,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_receiptImagePath!),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _viewReceiptImage,
              icon: const Icon(Icons.visibility, size: 20),
              label: const Text('Ver'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickReceiptImage,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Cambiar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> categoryIcons = <String, IconData>{
      'Alimentación': Icons.restaurant,
      'Comida': Icons.restaurant,
      'Transporte': Icons.directions_bus,
      'Hogar': Icons.home,
      'Entretenimiento': Icons.movie,
      'Compras': Icons.shopping_bag,
      'Salud': Icons.local_hospital,
      'Créditos': Icons.credit_card,
      'Ingreso': Icons.attach_money,
      'Otros': Icons.more_horiz,
    };
    return categoryIcons[category] ?? Icons.receipt;
  }
}

// Visor de imagen de recibo a pantalla completa
class _ReceiptImageViewer extends StatelessWidget {
  final String imagePath;

  const _ReceiptImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Recibo'),
      elevation: 0,
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Image.file(File(imagePath)),
      ),
    ),
  );
}
