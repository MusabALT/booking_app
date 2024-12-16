

class User {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String phoneNumber;
  final String address;
  final String? fcmToken;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.phoneNumber,
    required this.address,
    this.fcmToken
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'address': address,
      'fcmToken': fcmToken,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      phoneNumber: map['phoneNumber'] as String,
      address: map['address'] as String,
      fcmToken: map['fcmToken'] as String?,
    );
  }
}
