import 'package:flutter/material.dart';

class Worker {
  final String id;
  final String name;
  final String phone;
  final String role;
  String status;

  Worker({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'Worker',
    this.status = 'Not marked',
  });

  Color get statusColor {
    switch (status) {
      case 'Present':
        return const Color(0xFF22C55E);
      case 'Absent':
        return const Color(0xFFEF4444);
      case 'Half-day':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }
}
