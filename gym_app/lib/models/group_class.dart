class GroupClass {
  final int id;
  final String name;
  final int? trainerId;
  final String? description;
  final int maxParticipants;
  final String? room;
  final String? trainerName; // Tên huấn luyện viên dạy lớp này

  GroupClass({
    required this.id,
    required this.name,
    this.trainerId,
    this.description,
    required this.maxParticipants,
    this.room,
    this.trainerName,
  });

  factory GroupClass.fromJson(Map<String, dynamic> json) {
    return GroupClass(
      id: json['id'] as int,
      name: json['name'] as String,
      trainerId: json['trainer_id'] as int?,
      description: json['description'] as String?,
      maxParticipants: json['max_participants'] as int? ?? 20,
      room: json['room'] as String?,
      trainerName: json['trainer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'trainer_id': trainerId,
      'description': (description == null || description!.isEmpty) ? null : description,
      'max_participants': maxParticipants,
      'room': (room == null || room!.isEmpty) ? null : room,
    };
  }
}
