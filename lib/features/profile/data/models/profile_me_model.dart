class ProfileMeModel {
  ProfileMeModel({required this.fullName, required this.email});

  final String fullName;
  final String email;

  factory ProfileMeModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    final String? name =
        (map['full_name'] ?? map['nombre_completo'])?.toString();
    final String? mail = (map['email'])?.toString();
    return ProfileMeModel(fullName: name ?? '', email: mail ?? '');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'full_name': fullName,
    'email': email,
  };
}
