import 'package:json_annotation/json_annotation.dart';

part 'current_user_response.g.dart';

@JsonSerializable()
class CurrentUserResponse {
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_superuser')
  final bool isSuperuser;
  final int id;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  CurrentUserResponse({
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.isActive,
    required this.isSuperuser,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CurrentUserResponse.fromJson(Map<String, dynamic> json) => 
      _$CurrentUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentUserResponseToJson(this);
}
