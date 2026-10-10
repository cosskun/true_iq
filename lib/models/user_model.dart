class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String password; // Basit hash / şifre kontrolü
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'username': username,
    'password': password,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    password: json['password'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
