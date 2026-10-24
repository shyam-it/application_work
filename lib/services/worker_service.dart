import 'package:flutter/foundation.dart';

import '../models/worker.dart';

class WorkerService extends ChangeNotifier {
  WorkerService._();

  static final WorkerService instance = WorkerService._();

  final List<Worker> _workers = [
    Worker(
      id: 'WK001',
      name: 'Rahul Patel',
      phone: '9876543210',
      status: 'Present',
    ),
    Worker(
      id: 'WK002',
      name: 'Amit Shah',
      phone: '9876543211',
      status: 'Absent',
    ),
    Worker(
      id: 'WK003',
      name: 'Vijay Parmar',
      phone: '9876543212',
      status: 'Half-day',
    ),
  ];

  List<Worker> get workers => List.unmodifiable(_workers);

  int get totalWorkers => _workers.length;

  int get presentCount =>
      _workers.where((worker) => worker.status == 'Present').length;

  bool phoneExists(String phone) {
    return _workers.any((worker) => worker.phone == phone);
  }

  void addWorker({required String name, required String phone}) {
    if (phoneExists(phone)) {
      throw ArgumentError('This mobile number already exists.');
    }

    final nextId = _workers.length + 1;

    _workers.add(
      Worker(
        id: 'WK${nextId.toString().padLeft(3, '0')}',
        name: name,
        phone: phone,
      ),
    );

    notifyListeners();
  }

  void updateStatus(String workerId, String status) {
    final index = _workers.indexWhere((worker) => worker.id == workerId);

    if (index == -1) return;

    _workers[index].status = status;
    notifyListeners();
  }

  Worker? findById(String id) {
    for (final worker in _workers) {
      if (worker.id == id) return worker;
    }

    return null;
  }
}
