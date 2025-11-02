class RegisterUserRequest {
  RegisterUserRequest({
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.username,
    required this.email,
    required this.emailConfirmacion,
    required this.password,
    required this.passwordConfirmacion,
    this.firebaseUid,
  });

  final String nombres;
  final String apellidos;
  final String fechaNacimiento;
  final String username;
  final String email;
  final String emailConfirmacion;
  final String password;
  final String passwordConfirmacion;
  final String? firebaseUid;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nombres': nombres,
    'apellidos': apellidos,
    'fecha_nacimiento': fechaNacimiento,
    'username': username,
    'email': email,
    'email_confirmacion': emailConfirmacion,
    'password': password,
    'password_confirmacion': passwordConfirmacion,
    if (firebaseUid != null) 'firebase_uid': firebaseUid,
  };

  RegisterUserRequest copyWith({
    String? nombres,
    String? apellidos,
    String? fechaNacimiento,
    String? username,
    String? email,
    String? emailConfirmacion,
    String? password,
    String? passwordConfirmacion,
    String? firebaseUid,
  }) => RegisterUserRequest(
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    username: username ?? this.username,
    email: email ?? this.email,
    emailConfirmacion: emailConfirmacion ?? this.emailConfirmacion,
    password: password ?? this.password,
    passwordConfirmacion: passwordConfirmacion ?? this.passwordConfirmacion,
    firebaseUid: firebaseUid ?? this.firebaseUid,
  );
}
