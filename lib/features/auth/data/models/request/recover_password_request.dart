class RecoverPasswordRequest {
  final String email;

  RecoverPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}
