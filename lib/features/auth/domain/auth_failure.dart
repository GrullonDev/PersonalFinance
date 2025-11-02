import 'package:equatable/equatable.dart';

class AuthFailure extends Equatable {
  const AuthFailure({
    required this.message,
    this.statusCode,
    this.shouldNavigateToRegister = false,
  });

  final String message;
  final int? statusCode;
  final bool shouldNavigateToRegister;

  factory AuthFailure.serverError({
    String? message,
    int? statusCode,
    bool shouldNavigateToRegister = false,
  }) => AuthFailure(
    message: message ?? 'Error del servidor. Por favor, intente nuevamente.',
    statusCode: statusCode,
    shouldNavigateToRegister: shouldNavigateToRegister,
  );

  factory AuthFailure.unexpectedError() => const AuthFailure(
    message: 'Ocurrió un error inesperado. Por favor, intente nuevamente.',
  );

  @override
  List<Object?> get props => <Object?>[
    message,
    statusCode,
    shouldNavigateToRegister,
  ];
}
