class Plan {
  final int id;
  final String name;
  final String description;
  final num minAmount;
  final num? maxAmount;
  final int durationMonths; // 0 for flexible
  final double interestRate; // percent, e.g. 10.0
  final String interestType; // 'simple' or 'compound'
  final bool withInterest;
  final bool isLocked; // if true, cannot withdraw before maturity

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.minAmount,
    required this.maxAmount,
    required this.durationMonths,
    required this.interestRate,
    required this.interestType,
    required this.withInterest,
    required this.isLocked,
  });

  factory Plan.fromJson(Map<String, dynamic> j) {
    return Plan(
      id: j['id'],
      name: j['name'] ?? '',
      description: j['description'] ?? '',
      minAmount: (j['min_amount'] ?? 0),
      maxAmount: j['max_amount'],
      durationMonths: (j['duration_months'] ?? 0),
      interestRate: (j['interest_rate'] ?? 0).toDouble(),
      interestType: (j['interest_type'] ?? 'simple'),
      withInterest: (j['with_interest'] ?? false),
      isLocked: (j['is_locked'] ?? false),
    );
  }
}
