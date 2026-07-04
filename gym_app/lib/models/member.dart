enum Gender { male, female, other }

Gender genderFromString(String? value) {
  return Gender.values.firstWhere(
    (e) => e.name == value,
    orElse: () => Gender.other,
  );
}

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }
}

class Member {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final Gender gender;
  final DateTime? dob;
  final String? address;
  final String? note;
  final DateTime joinDate;
  final String status; // active | inactive

  Member({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.gender,
    this.dob,
    this.address,
    this.note,
    required this.joinDate,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      gender: genderFromString(json['gender'] as String?),
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      address: json['address'] as String?,
      note: json['note'] as String?,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'email': (email == null || email!.isEmpty) ? null : email,
      'gender': gender.name,
      'dob': dob != null ? _formatDate(dob!) : null,
      'address': (address == null || address!.isEmpty) ? null : address,
      'note': (note == null || note!.isEmpty) ? null : note,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toCreateJson();
    json['status'] = status;
    return json;
  }

  static String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
