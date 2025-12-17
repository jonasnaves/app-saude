class UserModel {
  final String id;
  final String name;
  final String email;
  final double credits;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.credits,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      credits: (json['credits'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'credits': credits,
    };
  }
}

