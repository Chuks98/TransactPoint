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
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Plan(
      id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
      name: j['name'] ?? '',
      description: j['description'] ?? '',
      minAmount: parseNum(j['min_amount']),
      maxAmount: j['max_amount'] != null ? parseNum(j['max_amount']) : null,
      durationMonths:
          j['duration_months'] is String
              ? int.tryParse(j['duration_months']) ?? 0
              : (j['duration_months'] ?? 0),
      interestRate: parseDouble(j['interest_rate']),
      interestType: j['interest_type'] ?? 'simple',
      withInterest: (j['with_interest'] == 1 || j['with_interest'] == true),
      isLocked: (j['is_locked'] == 1 || j['is_locked'] == true),
    );
  }
}
