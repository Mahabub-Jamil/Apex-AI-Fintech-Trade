class UserEntity {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final double balanceUSD;
  // Additional properties as needed by domain logic
  
  UserEntity({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.balanceUSD,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map, String uid) {
    return UserEntity(
      uid: uid,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      balanceUSD: (map['balanceUSD'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'balanceUSD': balanceUSD,
    };
  }
}
