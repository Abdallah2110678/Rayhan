class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.reason,
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  final String id;
  final DateTime date;
  final double amount;
  final String reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'reason': reason,
    };
  }
}
