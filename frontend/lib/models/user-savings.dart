class UserSaving {
  final int id;
  final int planId;
  final String planName;
  final double principal;
  final double maturityAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool withdrawn;
  final bool matured;

  UserSaving({
    required this.id,
    required this.planId,
    required this.planName,
    required this.principal,
    required this.maturityAmount,
    required this.startDate,
    required this.endDate,
    required this.withdrawn,
    required this.matured,
  });

  factory UserSaving.fromJson(Map<String, dynamic> j) {
    return UserSaving(
      id: j['id'],
      planId: j['plan_id'],
      planName: j['plan_name'] ?? '',
      principal: (j['principal'] ?? 0).toDouble(),
      maturityAmount: (j['maturity_amount'] ?? 0).toDouble(),
      startDate: DateTime.parse(j['start_date']),
      endDate: DateTime.parse(j['end_date']),
      withdrawn: (j['withdrawn'] ?? false),
      matured: DateTime.parse(j['end_date']).isBefore(DateTime.now()),
    );
  }

  double progress() {
    final total = endDate.difference(startDate).inSeconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startDate).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
