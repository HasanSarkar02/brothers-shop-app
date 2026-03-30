class AuthUser {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;

  AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
    avatar: json['avatar']?.toString(),
  );
}
