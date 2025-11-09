import 'package:json_annotation/json_annotation.dart';

part 'login_user_response.g.dart';

// Run 'dart run build_runner build' to generate the *.g.dart files

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.username,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'firebase_uid')
  final String firebaseUid;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'username')
  final String username;

  @JsonKey(name: 'nombres')
  final String nombres;

  @JsonKey(name: 'apellidos')
  final String apellidos;

  @JsonKey(name: 'nombre_completo')
  final String nombreCompleto;

  @JsonKey(name: 'fecha_nacimiento')
  final String fechaNacimiento;

  @JsonKey(name: 'fecha_creacion')
  final String fechaCreacion;

  @JsonKey(name: 'fecha_actualizacion')
  final String fechaActualizacion;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class LoginUserResponse {
  const LoginUserResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.refreshToken,
  });

  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'user')
  final User user;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  factory LoginUserResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginUserResponseToJson(this);
}
