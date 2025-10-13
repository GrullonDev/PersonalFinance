import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:personal_finance/features/transactions/models/transaction_detail.dart';
import 'package:personal_finance/features/transactions/widgets/transaction_filters_modal.dart';

class TransactionDetailLogic extends ChangeNotifier {
  final TransactionDetail transaction;
  String? _receiptImagePath;
  bool _isExpanded = false;
  final ImagePicker _picker = ImagePicker();

  TransactionDetailLogic({required this.transaction}) {
    _receiptImagePath = transaction.receiptImagePath;
  }

  String? get receiptImagePath => _receiptImagePath;
  bool get isExpanded => _isExpanded;

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  Future<void> pickReceiptImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        _receiptImagePath = image.path;
        notifyListeners();

        if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showFiltersModal(BuildContext context) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const TransactionFiltersModal(),
    ).then((Map<String, dynamic>? result) {
      if (result != null) {
        // Implementar lógica para aplicar filtros
      }
    });
  }

  void previewReceipt(BuildContext context) {
    if (_receiptImagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) =>
                  _ReceiptImageViewer(imagePath: _receiptImagePath!),
        ),
      );
    }
  }
}

class _ReceiptImageViewer extends StatelessWidget {
  final String imagePath;

  const _ReceiptImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vista del Recibo'),
      backgroundColor: Colors.black,
    ),
    backgroundColor: Colors.black,
    body: Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Image.file(File(imagePath)),
      ),
    ),
  );
}
