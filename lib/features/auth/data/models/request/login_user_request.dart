import 'package:json_annotation/json_annotation.dart';

part 'login_user_request.g.dart';

@JsonSerializable()
class LoginUserRequest {
  const LoginUserRequest({
    required this.email,
    required this.password,
    this.firebaseUid,
  });

  final String email;
  final String password;
  final String? firebaseUid;

  Map<String, dynamic> toJson() => _$LoginUserRequestToJson(this);

  factory LoginUserRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginUserRequestFromJson(json);

  LoginUserRequest copyWith({
    String? email,
    String? password,
    String? firebaseUid,
  }) => LoginUserRequest(
    email: email ?? this.email,
    password: password ?? this.password,
    firebaseUid: firebaseUid ?? this.firebaseUid,
  );
}
