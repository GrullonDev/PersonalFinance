class ProfileMeModel {
  ProfileMeModel({
    required this.fullName,
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.phoneNumber,
    this.address,
    this.photoUrl,
  });

  final String fullName;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? phoneNumber;
  final String? address;
  final String? photoUrl;

  factory ProfileMeModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    final String? name =
        (map['full_name'] ?? map['nombre_completo'])?.toString();
    final String? mail = (map['email'])?.toString();
    final String? photo = (map['photoUrl'] ?? map['photo_url'])?.toString();
    final String? first = (map['firstName'] ?? map['first_name'])?.toString();
    final String? last = (map['lastName'] ?? map['last_name'])?.toString();
    final String? user = (map['username'])?.toString();
    final String? phone =
        (map['phoneNumber'] ?? map['phone_number'])?.toString();
    final String? addr = (map['address'])?.toString();

    return ProfileMeModel(
      fullName: name ?? '',
      email: mail ?? '',
      photoUrl: photo,
      firstName: first,
      lastName: last,
      username: user,
      phoneNumber: phone,
      address: addr,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'full_name': fullName,
    'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (username != null) 'username': username,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (address != null) 'address': address,
  };
}
