enum RegistrationStatus { registered, attended, absent, cancelled }

extension RegistrationStatusLabel on RegistrationStatus {
  String get label {
    switch (this) {
      case RegistrationStatus.registered:
        return 'Đã đăng ký';
      case RegistrationStatus.attended:
        return 'Có mặt';
      case RegistrationStatus.absent:
        return 'Vắng mặt';
      case RegistrationStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

RegistrationStatus registrationStatusFromString(String value) {
  return RegistrationStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => RegistrationStatus.registered,
  );
}

class ClassRegistration {
  final int id;
  final int classScheduleId;
  final int memberId;
  final RegistrationStatus status;
  final DateTime registeredAt;

  // Helper fields for showing attendee details
  final String? memberName;
  final String? memberPhone;

  ClassRegistration({
    required this.id,
    required this.classScheduleId,
    required this.memberId,
    required this.status,
    required this.registeredAt,
    this.memberName,
    this.memberPhone,
  });

  factory ClassRegistration.fromJson(Map<String, dynamic> json) {
    return ClassRegistration(
      id: json['id'] as int,
      classScheduleId: json['class_schedule_id'] as int,
      memberId: json['member_id'] as int,
      status: registrationStatusFromString(json['status'] as String? ?? 'registered'),
      registeredAt: DateTime.parse(json['registered_at'] as String),
      memberName: json['member_name'] as String?,
      memberPhone: json['member_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_schedule_id': classScheduleId,
      'member_id': memberId,
    };
  }
}
