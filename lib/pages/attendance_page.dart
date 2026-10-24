import 'package:flutter/material.dart';

import '../models/worker.dart';
import '../services/worker_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime selectedDate = DateTime.now();

  final WorkerService workerService = WorkerService.instance;

  @override
  void initState() {
    super.initState();
    workerService.addListener(_onWorkersChanged);
  }

  void _onWorkersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    workerService.removeListener(_onWorkersChanged);
    super.dispose();
  }

  int get presentCount => workerService.workers
      .where((worker) => worker.status == 'Present')
      .length;

  int get absentCount =>
      workerService.workers.where((worker) => worker.status == 'Absent').length;

  int get halfDayCount => workerService.workers
      .where((worker) => worker.status == 'Half-day')
      .length;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              surface: Color(0xFF151B2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void updateStatus(String workerId, String status) {
    workerService.updateStatus(workerId, status);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF22C55E);
      case 'Absent':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = workerService.workers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select date',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Date',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedDate.day.toString().padLeft(2, '0')}/'
                          '${selectedDate.month.toString().padLeft(2, '0')}/'
                          '${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: pickDate, child: const Text('Change')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _SummaryCard(
                  title: 'Present',
                  count: presentCount,
                  color: const Color(0xFF22C55E),
                  icon: Icons.check_circle_outline,
                ),
                _SummaryCard(
                  title: 'Absent',
                  count: absentCount,
                  color: const Color(0xFFEF4444),
                  icon: Icons.cancel_outlined,
                ),
                _SummaryCard(
                  title: 'Half-day',
                  count: halfDayCount,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.timelapse,
                ),
                _SummaryCard(
                  title: 'Total Workers',
                  count: workers.length,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Workers Attendance',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (workers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No workers added yet.')),
              )
            else
              ...workers.map((Worker worker) {
                final status = worker.status;

                return Container(
                  key: ValueKey(worker.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.18),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  worker.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  worker.id,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor(
                                status,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatusButton(
                            label: 'Present',
                            selected: status == 'Present',
                            color: const Color(0xFF22C55E),
                            onTap: () => updateStatus(worker.id, 'Present'),
                          ),
                          const SizedBox(width: 6),
                          _StatusButton(
                            label: 'Absent',
                            selected: status == 'Absent',
                            color: const Color(0xFFEF4444),
                            onTap: () => updateStatus(worker.id, 'Absent'),
                          ),
                          const SizedBox(width: 6),
                          _StatusButton(
                            label: 'Half-day',
                            selected: status == 'Half-day',
                            color: const Color(0xFFF59E0B),
                            onTap: () => updateStatus(worker.id, 'Half-day'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          backgroundColor: selected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          foregroundColor: selected ? color : Colors.white60,
          side: BorderSide(color: selected ? color : Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
