import 'package:personal_finance/utils/constants.dart';

/// Sistema de validaciones centralizado
/// Proporciona validaciones consistentes en toda la aplicación
class AppValidators {
  // Constructor privado para evitar instanciación
  AppValidators._();
  
  // ===== VALIDACIONES DE TEXTO =====
  
  /// Valida si un texto no está vacío
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  /// Valida la longitud de un texto
  static String? validateLength(String? value, String fieldName, int minLength, int maxLength) {
    if (value == null) return '$fieldName es requerido';
    
    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    
    if (value.length > maxLength) {
      return '$fieldName debe tener máximo $maxLength caracteres';
    }
    
    return null;
  }
  
  /// Valida un título de transacción
  static String? validateTransactionTitle(String? value) => validateLength(value, 'Título', 1, AppConstants.maxTitleLength);
  
  /// Valida una descripción
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Descripción es opcional
    }
    return validateLength(value, 'Descripción', 1, AppConstants.maxDescriptionLength);
  }
  
  // ===== VALIDACIONES NUMÉRICAS =====
  
  /// Valida si un valor es un número válido
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    
    final double? number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    
    return null;
  }
  
  /// Valida un monto de transacción
  static String? validateAmount(String? value) {
    final String? numberError = validateNumber(value, 'Monto');
    if (numberError != null) return numberError;
    
    final double amount = double.parse(value!);
    
    if (amount < AppConstants.minAmount) {
      return 'El monto debe ser mayor a ${AppConstants.formatCurrency(AppConstants.minAmount)}';
    }
    
    if (amount > AppConstants.maxAmount) {
      return 'El monto no puede exceder ${AppConstants.formatCurrency(AppConstants.maxAmount)}';
    }
    
    return null;
  }
  
  /// Valida un porcentaje
  static String? validatePercentage(String? value) {
    final String? numberError = validateNumber(value, 'Porcentaje');
    if (numberError != null) return numberError;
    
    final double percentage = double.parse(value!);
    
    if (percentage < 0 || percentage > 100) {
      return 'El porcentaje debe estar entre 0 y 100';
    }
    
    return null;
  }
  
  // ===== VALIDACIONES DE FECHA =====
  
  /// Valida si una fecha es válida
  static String? validateDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName es requerido';
    }
    
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(2000);
    final DateTime maxDate = DateTime(now.year + 10, 12, 31);
    
    if (date.isBefore(minDate)) {
      return '$fieldName no puede ser anterior al año 2000';
    }
    
    if (date.isAfter(maxDate)) {
      return '$fieldName no puede ser posterior al año ${maxDate.year}';
    }
    
    return null;
  }
  
  /// Valida si una fecha está en el futuro
  static String? validateFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName es requerido';
    }
    
    final DateTime now = DateTime.now();
    if (date.isBefore(now)) {
      return '$fieldName debe ser una fecha futura';
    }
    
    return null;
  }
  
  /// Valida si una fecha está en el pasado
  static String? validatePastDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName es requerido';
    }
    
    final DateTime now = DateTime.now();
    if (date.isAfter(now)) {
      return '$fieldName debe ser una fecha pasada';
    }
    
    return null;
  }
  
  // ===== VALIDACIONES DE CATEGORÍAS =====
  
  /// Valida una categoría de gasto
  static String? validateExpenseCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Categoría es requerida';
    }
    
    if (!AppConstants.expenseCategories.contains(value)) {
      return 'Categoría no válida';
    }
    
    return null;
  }
  
  /// Valida una fuente de ingreso
  static String? validateIncomeSource(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fuente de ingreso es requerida';
    }
    
    if (!AppConstants.incomeSources.contains(value)) {
      return 'Fuente de ingreso no válida';
    }
    
    return null;
  }
  
  // ===== VALIDACIONES COMPUESTAS =====
  
  /// Valida una transacción completa
  static Map<String, String?> validateTransaction({
    String? title,
    String? amount,
    DateTime? date,
    String? category,
    String? description,
  }) => <String, String?>{
      'title': validateTransactionTitle(title),
      'amount': validateAmount(amount),
      'date': validateDate(date, 'Fecha'),
      'category': validateExpenseCategory(category),
      'description': validateDescription(description),
    };
  
  /// Valida un ingreso completo
  static Map<String, String?> validateIncome({
    String? title,
    String? amount,
    DateTime? date,
    String? source,
    String? description,
  }) => <String, String?>{
      'title': validateTransactionTitle(title),
      'amount': validateAmount(amount),
      'date': validateDate(date, 'Fecha'),
      'source': validateIncomeSource(source),
      'description': validateDescription(description),
    };
  
  /// Verifica si hay errores en un mapa de validaciones
  static bool hasErrors(Map<String, String?> validations) => validations.values.any((String? error) => error != null);
  
  /// Obtiene el primer error de un mapa de validaciones
  static String? getFirstError(Map<String, String?> validations) {
    for (final String? error in validations.values) {
      if (error != null) return error;
    }
    return null;
  }
  
  /// Obtiene todos los errores de un mapa de validaciones
  static List<String> getAllErrors(Map<String, String?> validations) => validations.values
        .where((String? error) => error != null)
        .map((String? error) => error!)
        .toList();
} 