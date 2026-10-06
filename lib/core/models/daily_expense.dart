class DailyExpense {
  final int? id;
  final double amount;
  final String date;
  final String? note;
  final String createdAt;
  final String updatedAt;

  DailyExpense({
    this.id,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyExpense.fromMap(Map<String, dynamic> json) {
    return DailyExpense(
      id: json['id'],
      amount: json['amount'],
      date: json['date'],
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
