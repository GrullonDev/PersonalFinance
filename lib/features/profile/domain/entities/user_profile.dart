import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String username;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? address;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.username,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.address,
  });

  String get name => '$firstName $lastName'.trim();

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) =>
      UserProfile(
        id: id,
        firstName: (map['firstName'] ?? '') as String,
        lastName: (map['lastName'] ?? '') as String,
        birthDate: (map['birthDate'] as Timestamp).toDate(),
        username: (map['username'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        photoUrl: map['photoUrl'] as String?,
        phoneNumber: map['phoneNumber'] as String?,
        address: map['address'] as String?,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': Timestamp.fromDate(birthDate),
    'username': username,
    'email': email,
    'photoUrl': photoUrl,
    'phoneNumber': phoneNumber,
    'address': address,
  };

  /* UserProfile copyWith({String? photoUrl}) => UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    username: username,
    email: email,
    photoUrl: photoUrl ?? this.photoUrl,
  ); */

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? username,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    String? address,
  }) => UserProfile(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    username: username ?? this.username,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    address: address ?? this.address,
  );
}
