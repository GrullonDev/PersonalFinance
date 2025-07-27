import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String username;
  final String email;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.username,
    required this.email,
    this.photoUrl,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': Timestamp.fromDate(birthDate),
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({String? photoUrl}) {
    return UserProfile(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      username: username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
