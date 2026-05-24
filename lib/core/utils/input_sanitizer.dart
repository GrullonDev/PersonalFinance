class InputSanitizer {
  // Para texto libre (notas, descripciones)
  static String sanitizeText(String input, {int maxLength = 500}) {
    final sanitized = input
        .replaceAll(RegExp(r'[<>"\']'), '') // Eliminar caracteres HTML peligrosos
        .trim();
    if (sanitized.length <= maxLength) {
      return sanitized;
    }
    return sanitized.substring(0, maxLength);
  }

  // Para nombres (cuentas, categorias, metas)
  static String? validateName(String input, {int max = 120}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'El nombre no puede estar vacío';
    if (trimmed.length > max) return 'Máximo $max caracteres';
    // Solo permitir texto, numeros, espacios, y puntuacion basica
    if (!RegExp(r"^[\w\s\-\.,áéíóúÁÉÍÓÚñÑüÜ]+$").hasMatch(trimmed)) {
      return 'El nombre contiene caracteres no permitidos';
    }
    return null; // null = valido
  }

  // Para montos monetarios
  static String? validateAmount(String input) {
    final value = double.tryParse(input.replaceAll(',', '.'));
    if (value == null) return 'Ingresa un monto válido';
    if (value <= 0) return 'El monto debe ser mayor a 0';
    if (value > 999999999) return 'Monto demasiado grande';
    return null;
  }

  // Para colores hex
  static String? validateColor(String input) {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(input)) {
      return 'Color inválido';
    }
    return null;
  }
}
