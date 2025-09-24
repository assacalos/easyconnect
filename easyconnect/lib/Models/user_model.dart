class UserModel {
  final int id;
  final String? nom;
  final String? prenom;
  final String? email;
  final int? role;
  final dynamic createdAt;
  final dynamic updatedAt;
  final bool isActive;

  UserModel({
    required this.id,
    this.nom,
    this.prenom,
    this.email,
    this.role,
    this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Conversion ID en int
    int idValue;
    if (json['id'] is String) {
      idValue = int.parse(json['id']);
    } else {
      idValue = json['id'];
    }

    // Conversion rôle en int
    int? roleValue;
    if (json['role'] != null) {
      roleValue =
          json['role'] is String ? int.tryParse(json['role']) : json['role'];
    }

    // Conversion isActive en bool
    bool activeValue;
    if (json['isActive'] is int) {
      activeValue = json['isActive'] == 1;
    } else {
      activeValue = json['isActive'] ?? true;
    }

    return UserModel(
      id: idValue,
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      role: roleValue,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isActive: activeValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'role': role,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'isActive': isActive ? 1 : 0, // pour Laravel
  };
}
