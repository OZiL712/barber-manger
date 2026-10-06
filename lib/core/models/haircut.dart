import 'barber_service.dart';

class Haircut {
  final int? id;
  final String operationNumber;
  final String date; // Format: yyyy-MM-dd
  final String time; // Format: HH:mm
  final double price;
  final double amountReceived;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<BarberService> services;

  Haircut({
    this.id,
    required this.operationNumber,
    required this.date,
    required this.time,
    required this.price,
    required this.amountReceived,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.services = const [],
  });

  factory Haircut.fromMap(Map<String, dynamic> json, [List<BarberService> services = const []]) {
    return Haircut(
      id: json['id'],
      operationNumber: json['operation_number'],
      date: json['date'],
      time: json['time'],
      price: json['price'],
      amountReceived: json['amount_received'],
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      services: services,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation_number': operationNumber,
      'date': date,
      'time': time,
      'price': price,
      'amount_received': amountReceived,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
