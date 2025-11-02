class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'refresh_token': refreshToken,
  };
}
