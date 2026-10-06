import 'package:flutter/material.dart';

class WorkerDeposit {
  final int? id;
  final String operationNumber;
  final double amount;
  final String date;
  final String time;
  final String? note;
  final String createdAt;
  final String updatedAt;

  WorkerDeposit({
    this.id,
    required this.operationNumber,
    required this.amount,
    required this.date,
    required this.time,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkerDeposit.fromMap(Map<String, dynamic> json) {
    return WorkerDeposit(
      id: json['id'],
      operationNumber: json['operation_number'],
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
      'operation_number': operationNumber,
      'amount': amount,
      'date': date,
      'time': time,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
