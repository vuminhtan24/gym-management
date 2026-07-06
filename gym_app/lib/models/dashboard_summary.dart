class DashboardSummary {
  final int totalMembers;
  final int activeMembers;
  final int totalTrainers;
  final int totalStaff;
  final int activeSubscriptions;
  final double revenueThisMonth;
  final int newMembersThisMonth;
  final int upcomingPtSessions;
  final int upcomingClassSessions;

  DashboardSummary({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalTrainers,
    required this.totalStaff,
    required this.activeSubscriptions,
    required this.revenueThisMonth,
    required this.newMembersThisMonth,
    required this.upcomingPtSessions,
    required this.upcomingClassSessions,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalMembers: json['total_members'] as int? ?? 0,
      activeMembers: json['active_members'] as int? ?? 0,
      totalTrainers: json['total_trainers'] as int? ?? 0,
      totalStaff: json['total_staff'] as int? ?? 0,
      activeSubscriptions: json['active_subscriptions'] as int? ?? 0,
      revenueThisMonth: (json['revenue_this_month'] as num? ?? 0).toDouble(),
      newMembersThisMonth: json['new_members_this_month'] as int? ?? 0,
      upcomingPtSessions: json['upcoming_pt_sessions'] as int? ?? 0,
      upcomingClassSessions: json['upcoming_class_sessions'] as int? ?? 0,
    );
  }
}

class RevenuePoint {
  final String period; // ví dụ "2026-06"
  final double revenue;
  final int subscriptionCount;

  RevenuePoint({
    required this.period,
    required this.revenue,
    required this.subscriptionCount,
  });

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      period: json['period'] as String? ?? '',
      revenue: (json['revenue'] as num? ?? 0).toDouble(),
      subscriptionCount: json['subscription_count'] as int? ?? 0,
    );
  }
}

class PackageSalesPoint {
  final int packageId;
  final String packageName;
  final int soldCount;
  final double totalRevenue;

  PackageSalesPoint({
    required this.packageId,
    required this.packageName,
    required this.soldCount,
    required this.totalRevenue,
  });

  factory PackageSalesPoint.fromJson(Map<String, dynamic> json) {
    return PackageSalesPoint(
      packageId: json['package_id'] as int? ?? 0,
      packageName: json['package_name'] as String? ?? '',
      soldCount: json['sold_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num? ?? 0).toDouble(),
    );
  }
}

class TrainerSessionPoint {
  final int trainerId;
  final String trainerName;
  final int ptSessionCount;
  final int groupClassCount;

  TrainerSessionPoint({
    required this.trainerId,
    required this.trainerName,
    required this.ptSessionCount,
    required this.groupClassCount,
  });

  factory TrainerSessionPoint.fromJson(Map<String, dynamic> json) {
    return TrainerSessionPoint(
      trainerId: json['trainer_id'] as int? ?? 0,
      trainerName: json['trainer_name'] as String? ?? '',
      ptSessionCount: json['pt_session_count'] as int? ?? 0,
      groupClassCount: json['group_class_count'] as int? ?? 0,
    );
  }
}

class ClassAttendancePoint {
  final int classId;
  final String className;
  final int totalSessions;
  final int totalRegistrations;
  final int totalAttended;
  final double attendanceRate; // %

  ClassAttendancePoint({
    required this.classId,
    required this.className,
    required this.totalSessions,
    required this.totalRegistrations,
    required this.totalAttended,
    required this.attendanceRate,
  });

  factory ClassAttendancePoint.fromJson(Map<String, dynamic> json) {
    return ClassAttendancePoint(
      classId: json['class_id'] as int? ?? 0,
      className: json['class_name'] as String? ?? '',
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalRegistrations: json['total_registrations'] as int? ?? 0,
      totalAttended: json['total_attended'] as int? ?? 0,
      attendanceRate: (json['attendance_rate'] as num? ?? 0).toDouble(),
    );
  }
}
