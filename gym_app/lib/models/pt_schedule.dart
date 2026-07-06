class PTSchedule {
  final int id;
  final int memberId;
  final int trainerId;
  final DateTime date;
  final String startTime; // format HH:mm:ss
  final String endTime;   // format HH:mm:ss
  final String status;    // scheduled | completed | cancelled
  final String? notes;

  // Add optional names to make UI rendering easier if backend includes it (we can fetch trainer/member details or display)
  final String? memberName;
  final String? trainerName;

  PTSchedule({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    this.memberName,
    this.trainerName,
  });

  factory PTSchedule.fromJson(Map<String, dynamic> json) {
    return PTSchedule(
      id: json['id'] as int,
      memberId: json['member_id'] as int,
      trainerId: json['trainer_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
      memberName: json['member_name'] as String?,
      trainerName: json['trainer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'trainer_id': trainerId,
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'notes': (notes == null || notes!.isEmpty) ? null : notes,
    };
  }

  String get timeRange => '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
}
