import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScannedReceipt {
  final double? amount;
  final String? category;
  final String? title;

  ScannedReceipt({this.amount, this.category, this.title});
}

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  Future<ScannedReceipt?> scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    return _parseText(recognizedText.text);
  }

  ScannedReceipt _parseText(String text) {
    double? amount;
    String? category;
    String? title;

    // Basic amount parsing: look for numbers with decimals
    final RegExp amountRegExp = RegExp(r'(\d+[.,]\d{2})');
    final Iterable<RegExpMatch> matches = amountRegExp.allMatches(text);

    final List<double> amounts = [];
    for (final match in matches) {
      final val = match.group(0)?.replaceAll(',', '.');
      if (val != null) {
        final parsed = double.tryParse(val);
        if (parsed != null) amounts.add(parsed);
      }
    }

    if (amounts.isNotEmpty) {
      // Usually the total is the largest amount on the receipt
      amounts.sort();
      amount = amounts.last;
    }

    // Basic category/title guessing
    final textLower = text.toLowerCase();
    if (textLower.contains('restaurante') ||
        textLower.contains('comida') ||
        textLower.contains('food')) {
      category = 'Alimentación';
    } else if (textLower.contains('uber') ||
        textLower.contains('taxi') ||
        textLower.contains('gasolina')) {
      category = 'Transporte';
    } else if (textLower.contains('farmacia') ||
        textLower.contains('hospital')) {
      category = 'Salud';
    }

    // Try to get the first line as a potential title (usually store name)
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      title = lines.first.trim();
    }

    return ScannedReceipt(amount: amount, category: category, title: title);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
