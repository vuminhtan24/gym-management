class Trainer {
  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String? specialty;
  final int experienceYears;
  final double? salary;
  final String status; // active | inactive

  Trainer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.specialty,
    required this.experienceYears,
    this.salary,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      specialty: json['specialty'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      salary: json['salary'] != null ? (json['salary'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'email': (email == null || email!.isEmpty) ? null : email,
      'specialty': (specialty == null || specialty!.isEmpty) ? null : specialty,
      'experience_years': experienceYears,
      'salary': salary,
      'status': status,
    };
  }
}
