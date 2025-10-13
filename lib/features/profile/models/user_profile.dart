import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.photoUrl,
    this.lastUpdated,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final DateTime? lastUpdated;

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    DateTime? lastUpdated,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    email: json['email'] as String,
    photoUrl: json['photoUrl'] as String?,
    lastUpdated:
        json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
  );
}
