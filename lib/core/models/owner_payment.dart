class OwnerPayment {
  final int? id;
  final double amount;
  final String date;
  final String time;
  final String? note;
  final String createdAt;
  final String updatedAt;

  OwnerPayment({
    this.id,
    required this.amount,
    required this.date,
    required this.time,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OwnerPayment.fromMap(Map<String, dynamic> json) {
    return OwnerPayment(
      id: json['id'],
      amount: json['amount'],
      date: json['date'],
      time: json['time'],
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
      'time': time,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
