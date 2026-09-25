import 'package:get_it/get_it.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';

/// Resultado enriquecido de un documento financiero escaneado.
class ScannedDocument {
  final double? amount;
  final String? category;
  final String? title;
  final String? description;
  final String? rawText;

  const ScannedDocument({
    this.amount,
    this.category,
    this.title,
    this.description,
    this.rawText,
  });
}

/// Servicio de escaneo de documentos financieros.
/// Soporta cámara y galería. Usa ML Kit para OCR y Gemini para extracción inteligente.
class DocumentScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  /// Escanea con la cámara del dispositivo.
  Future<ScannedDocument?> scanFromCamera() =>
      _scanFromSource(ImageSource.camera);

  /// Selecciona un documento desde la galería (ej. foto de estado de cuenta).
  Future<ScannedDocument?> scanFromGallery() =>
      _scanFromSource(ImageSource.gallery);

  Future<ScannedDocument?> _scanFromSource(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognized = await _textRecognizer.processImage(
      inputImage,
    );
    final String ocrText = recognized.text;

    if (ocrText.trim().isEmpty) return null;

    // Intentar extracción inteligente con Gemini
    try {
      final aiService = GetIt.instance<VertexAiService>();
      final extracted = await aiService.extractFinancialDataFromDocument(
        ocrText,
      );

      if (extracted != null) {
        return ScannedDocument(
          amount: extracted.amount,
          category: extracted.category,
          title: extracted.merchant,
          description: extracted.description,
          rawText: ocrText,
        );
      }
    } catch (_) {
      // Si Gemini falla, caer al parser local
    }

    return _fallbackParse(ocrText);
  }

  /// Parser local de respaldo cuando Gemini no está disponible.
  ScannedDocument _fallbackParse(String text) {
    double? amount;
    String? category;
    String? title;

    final RegExp amountRegExp = RegExp(r'(\d+[.,]\d{2})');
    final amounts =
        amountRegExp
            .allMatches(text)
            .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')))
            .whereType<double>()
            .toList()
          ..sort();
    if (amounts.isNotEmpty) amount = amounts.last;

    final textLower = text.toLowerCase();
    if (textLower.contains('restaurante') ||
        textLower.contains('comida') ||
        textLower.contains('pollo') ||
        textLower.contains('pizza')) {
      category = 'Alimentación';
    } else if (textLower.contains('uber') ||
        textLower.contains('taxi') ||
        textLower.contains('gasolina') ||
        textLower.contains('combustible')) {
      category = 'Transporte';
    } else if (textLower.contains('farmacia') ||
        textLower.contains('hospital') ||
        textLower.contains('clínica')) {
      category = 'Salud';
    } else if (textLower.contains('supermercado') ||
        textLower.contains('walmart') ||
        textLower.contains('paiz') ||
        textLower.contains('la torre')) {
      category = 'Alimentación';
    }

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) title = lines.first.trim();

    return ScannedDocument(
      amount: amount,
      category: category,
      title: title,
      rawText: text,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
