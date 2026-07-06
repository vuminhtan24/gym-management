class ClassSchedule {
  final int id;
  final int classId;
  final DateTime date;
  final String startTime; // format HH:mm:ss
  final String endTime;   // format HH:mm:ss
  int registeredCount;   // Số lượng thành viên đã đăng ký

  // Helper fields for UI
  final String? className;
  final String? trainerName;
  final int? maxParticipants;
  final String? room;

  ClassSchedule({
    required this.id,
    required this.classId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.registeredCount = 0,
    this.className,
    this.trainerName,
    this.maxParticipants,
    this.room,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as int,
      classId: json['class_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      registeredCount: json['registered_count'] as int? ?? 0,
      className: json['class_name'] as String?,
      trainerName: json['trainer_name'] as String?,
      maxParticipants: json['max_participants'] as int?,
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get timeRange => '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
}
