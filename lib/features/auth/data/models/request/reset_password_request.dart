class ResetPasswordRequest {
  final String token;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  };
}
