import 'package:equatable/equatable.dart';

enum UserRole {
  customer,
  creator,
  admin;

  static UserRole fromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'creator':
        return UserRole.creator;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String toApiString() {
    switch (this) {
      case UserRole.creator:
        return 'creator';
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.creator:
        return 'Reel Creator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String? name;
  final String mobile;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.name,
    required this.mobile,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      mobile: json['mobile'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'role': role.toApiString(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? mobile,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, mobile, role, isActive, createdAt];
}
