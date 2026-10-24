import 'package:flutter/material.dart';

class Worker {
  final String id;
  final String name;
  final String phone;
  final String? uid;
  final bool isActive;

  const Worker({
    required this.id,
    required this.name,
    required this.phone,
    this.uid,
    this.isActive = true,
  });

  factory Worker.fromMap(String id, Map<String, dynamic> data) => Worker(
    id: id,
    name: data['name'] as String? ?? '',
    phone: data['phone'] as String? ?? '',
    uid: data['uid'] as String?,
    isActive: data['isActive'] as bool? ?? true,
  );

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'phone': phone.trim(),
    'uid': uid?.trim().isEmpty == true ? null : uid?.trim(),
    'isActive': isActive,
  };

  Color get statusColor => Colors.grey;
}
