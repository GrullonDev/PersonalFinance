class ProfileInfo {
  ProfileInfo({
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
}
