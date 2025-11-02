class RecoverPasswordRequest {
  final String email;

  RecoverPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}
