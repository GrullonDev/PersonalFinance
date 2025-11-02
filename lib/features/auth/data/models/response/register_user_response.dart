class RegisterUserResponse {
  RegisterUserResponse({
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

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) =>
      RegisterUserResponse(
        id: json['id'] as int,
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

  final int id;
  final String firebaseUid;
  final String email;
  final String username;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;
  final String fechaNacimiento;
  final String fechaCreacion;
  final String fechaActualizacion;
}
