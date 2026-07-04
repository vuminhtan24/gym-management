enum StaffRole { admin, manager, receptionist }

extension StaffRoleLabel on StaffRole {
  String get label {
    switch (this) {
      case StaffRole.admin:
        return 'Quản trị viên';
      case StaffRole.manager:
        return 'Quản lý';
      case StaffRole.receptionist:
        return 'Lễ tân';
    }
  }
}

StaffRole staffRoleFromString(String value) {
  return StaffRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => StaffRole.receptionist,
  );
}

class Staff {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final StaffRole role;
  final String username;
  final String status;

  Staff({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    required this.username,
    required this.status,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: staffRoleFromString(json['role'] as String),
      username: json['username'] as String,
      status: json['status'] as String,
    );
  }

  bool get isAdmin => role == StaffRole.admin;
  bool get isAdminOrManager => role == StaffRole.admin || role == StaffRole.manager;
}
