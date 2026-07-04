class Subscription {
  final int id;
  final int memberId;
  final int packageId;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePaid;
  final String status; // active | expired | cancelled

  Subscription({
    required this.id,
    required this.memberId,
    required this.packageId,
    required this.startDate,
    required this.endDate,
    required this.pricePaid,
    required this.status,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      memberId: json['member_id'] as int,
      packageId: json['package_id'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      pricePaid: (json['price_paid'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}
