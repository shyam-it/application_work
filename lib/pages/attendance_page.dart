import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/site.dart';
import '../models/worker.dart';
import '../services/attendance_service.dart';
import '../services/site_service.dart';
import '../services/worker_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, this.workerMode = false});

  final bool workerMode;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _attendance = AttendanceService();
  final _sites = SiteService();
  final _workers = WorkerService();

  DateTime _date = DateTime.now();

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _date = selectedDate;
      });
    }
  }

  Future<String?> _pickTime(BuildContext context, String initial) async {
    final parts = initial.split(':');

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      ),
    );

    if (selectedTime == null) return null;

    final hour = selectedTime.hour.toString().padLeft(2, '0');
    final minute = selectedTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _mark(Worker worker, List<Site> sites) async {
    String status = 'Present';

    final rows = <_SiteTimeDraft>[];

    if (sites.isNotEmpty) {
      rows.add(
        _SiteTimeDraft(siteId: sites.first.id, start: '09:00', end: '17:00'),
      );
    }

    String? error;

    final result = await showDialog<_AttendanceDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: Text('Attendance • ${worker.name}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const ['Present', 'Absent', 'Half-day'].map((
                          value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialog(() {
                            status = value ?? 'Present';

                            if (status == 'Absent') {
                              rows.clear();
                            } else if (rows.isEmpty && sites.isNotEmpty) {
                              rows.add(
                                _SiteTimeDraft(
                                  siteId: sites.first.id,
                                  start: '09:00',
                                  end: '17:00',
                                ),
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (status != 'Absent') ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: sites.isEmpty
                                ? null
                                : () {
                                    setDialog(() {
                                      rows.add(
                                        _SiteTimeDraft(
                                          siteId: sites.first.id,
                                          start: '09:00',
                                          end: '17:00',
                                        ),
                                      );
                                    });
                                  },
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Add work site'),
                          ),
                        ),
                        if (sites.isEmpty)
                          const Text('Owner must add active sites first.'),
                        ...rows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue:
                                              sites.any(
                                                (site) => site.id == row.siteId,
                                              )
                                              ? row.siteId
                                              : null,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Site',
                                          ),
                                          items: sites.map((site) {
                                            return DropdownMenuItem<String>(
                                              value: site.id,
                                              child: Text(site.name),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setDialog(() {
                                              row.siteId = value ?? '';
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setDialog(() {
                                            rows.removeAt(index);
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            final time = await _pickTime(
                                              context,
                                              row.start,
                                            );

                                            if (time != null) {
                                              setDialog(() {
                                                row.start = time;
                                              });
                                            }
                                          },
                                          child: Text('Start ${row.start}'),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            final time = await _pickTime(
                                              context,
                                              row.end,
                                            );

                                            if (time != null) {
                                              setDialog(() {
                                                row.end = time;
                                              });
                                            }
                                          },
                                          child: Text('End ${row.end}'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (error != null)
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (status != 'Absent' &&
                        (rows.isEmpty ||
                            rows.any((row) => row.siteId.isEmpty))) {
                      setDialog(() {
                        error = 'Select at least one site for this attendance.';
                      });
                      return;
                    }

                    for (final row in rows) {
                      if (row.end.compareTo(row.start) <= 0) {
                        setDialog(() {
                          error = 'End time must be after start time.';
                        });
                        return;
                      }
                    }

                    final times = rows.map((row) {
                      final site = sites.firstWhere(
                        (site) => site.id == row.siteId,
                      );

                      return SiteWorkTime(
                        siteId: site.id,
                        siteName: site.name,
                        startTime: row.start,
                        endTime: row.end,
                      );
                    }).toList();

                    Navigator.pop(
                      dialogContext,
                      _AttendanceDraft(status, times),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      await _attendance.save(
        workerId: worker.id,
        workerUid: worker.uid ?? '',
        workerName: worker.name,
        date: _dateKey(_date),
        status: result.status,
        siteWorkTimes: result.times,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved to Firestore.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save attendance: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workerMode) {
      return _buildWorkerView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Choose date',
          ),
        ],
      ),
      body: StreamBuilder<List<Worker>>(
        stream: _workers.watchWorkers(),
        builder: (context, workerSnapshot) {
          if (workerSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load workers. Check Firestore rules.'),
            );
          }

          if (!workerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Site>>(
            stream: _sites.watchActiveSites(),
            builder: (context, siteSnapshot) {
              if (siteSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load sites. Check Firestore rules.'),
                );
              }

              if (!siteSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final workers = workerSnapshot.data!;
              final sites = siteSnapshot.data!;

              return StreamBuilder<Map<String, AttendanceRecord>>(
                stream: _attendance.watchForDate(_dateKey(_date)),
                builder: (context, recordSnapshot) {
                  if (recordSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load attendance records.'),
                    );
                  }

                  if (!recordSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final records = recordSnapshot.data!;

                  final marked = workers.where((worker) {
                    final key = '${worker.id}_${_dateKey(_date)}';
                    return records.containsKey(key);
                  }).length;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Selected date'),
                          subtitle: Text(_dateKey(_date)),
                          trailing: TextButton(
                            onPressed: _pickDate,
                            child: const Text('Change'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Marked: $marked / ${workers.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (sites.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No active sites. Owner needs to add sites first.',
                            ),
                          ),
                        ),
                      ...workers.map((worker) {
                        final key = '${worker.id}_${_dateKey(_date)}';
                        final record = records[key];
                        final status = record?.status ?? 'Not marked';

                        final color = status == 'Present'
                            ? Colors.green
                            : status == 'Absent'
                            ? Colors.red
                            : status == 'Half-day'
                            ? Colors.orange
                            : Colors.grey;

                        final siteDetails = record == null
                            ? ''
                            : record.siteWorkTimes
                                  .map((item) {
                                    return '${item.siteName} (${item.startTime}-${item.endTime})';
                                  })
                                  .join(', ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(worker.name),
                            subtitle: Text(
                              record == null ? status : '$status\n$siteDetails',
                              style: const TextStyle(height: 1.4),
                            ),
                            isThreeLine:
                                record?.siteWorkTimes.isNotEmpty == true,
                            leading: CircleAvatar(
                              child: Text(
                                worker.name.isEmpty
                                    ? '?'
                                    : worker.name[0].toUpperCase(),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Mark attendance',
                              icon: Icon(Icons.edit_calendar, color: color),
                              onPressed: () => _mark(worker, sites),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkerView() {
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: _attendance.watchMyRecords(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load your attendance.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;

          if (records.isEmpty) {
            return const Center(child: Text('No attendance records yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: records.map((record) {
              final siteDetails = record.siteWorkTimes.isEmpty
                  ? 'No site recorded'
                  : record.siteWorkTimes
                        .map((item) {
                          return '${item.siteName}: ${item.startTime}–${item.endTime}';
                        })
                        .join('\n');

              return Card(
                child: ListTile(
                  title: Text('${record.date} • ${record.status}'),
                  subtitle: Text(siteDetails),
                  isThreeLine: record.siteWorkTimes.length > 1,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SiteTimeDraft {
  _SiteTimeDraft({
    required this.siteId,
    required this.start,
    required this.end,
  });

  String siteId;
  String start;
  String end;
}

class _AttendanceDraft {
  const _AttendanceDraft(this.status, this.times);

  final String status;
  final List<SiteWorkTime> times;
}
