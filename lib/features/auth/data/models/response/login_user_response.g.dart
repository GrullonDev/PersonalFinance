// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firebaseUid: json['firebase_uid'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  nombres: json['nombres'] as String,
  apellidos: json['apellidos'] as String,
  nombreCompleto: json['nombre_completo'] as String,
  fechaNacimiento: json['fecha_nacimiento'] as String,
  fechaCreacion: json['fecha_creacion'] as String,
  fechaActualizacion: json['fecha_actualizacion'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firebase_uid': instance.firebaseUid,
  'email': instance.email,
  'username': instance.username,
  'nombres': instance.nombres,
  'apellidos': instance.apellidos,
  'nombre_completo': instance.nombreCompleto,
  'fecha_nacimiento': instance.fechaNacimiento,
  'fecha_creacion': instance.fechaCreacion,
  'fecha_actualizacion': instance.fechaActualizacion,
};

LoginUserResponse _$LoginUserResponseFromJson(Map<String, dynamic> json) =>
    LoginUserResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginUserResponseToJson(LoginUserResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'user': instance.user,
    };
