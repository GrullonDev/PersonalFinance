class RefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final String refreshToken;

  RefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      RefreshTokenResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}
