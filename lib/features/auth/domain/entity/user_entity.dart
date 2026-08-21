/// Pure domain entity for the authenticated user. No Flutter, no JSON,
/// no third-party packages.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;

  String get displayName => '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserEntity &&
            other.id == id &&
            other.username == username &&
            other.email == email &&
            other.firstName == firstName &&
            other.lastName == lastName &&
            other.gender == gender;
  }

  @override
  int get hashCode => Object.hash(id, username, email, firstName, lastName, gender);
}