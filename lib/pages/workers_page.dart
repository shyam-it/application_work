import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../services/worker_service.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});
  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  final _service = WorkerService();
  final _search = TextEditingController();

  Future<void> _editWorker({Worker? worker}) async {
    final name = TextEditingController(text: worker?.name ?? '');
    final phone = TextEditingController(text: worker?.phone ?? '');
    final uid = TextEditingController(text: worker?.uid ?? '');
    try {
      final data = await showDialog<List<String>?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(worker == null ? 'Add Worker' : 'Edit Worker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: '10-digit mobile',
                  ),
                ),
                TextField(
                  controller: uid,
                  decoration: const InputDecoration(
                    labelText: 'Firebase Auth UID (optional)',
                    helperText:
                        'Create login in Firebase Auth, then paste UID here.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, [
                name.text.trim(),
                phone.text.trim(),
                uid.text.trim(),
              ]),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (data == null) return;
      if (worker == null) {
        await _service.addWorker(
          name: data[0],
          phone: data[1],
          uid: data[2].isEmpty ? null : data[2],
        );
      } else {
        await _service.updateWorker(
          worker,
          name: data[0],
          phone: data[1],
          uid: data[2].isEmpty ? null : data[2],
        );
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(worker == null ? 'Worker added.' : 'Worker updated.'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save worker: $e')));
    } finally {
      name.dispose();
      phone.dispose();
      uid.dispose();
    }
  }

  Future<void> _deactivate(Worker w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate worker?'),
        content: Text(
          '${w.name} will be hidden from active worker lists. Historical attendance and transactions will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deactivateWorker(w.id);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Worker deactivated.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not deactivate worker: $e')),
        );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Workers'),
      actions: [
        IconButton(
          onPressed: () => _editWorker(),
          icon: const Icon(Icons.person_add_alt_1),
          tooltip: 'Add worker',
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or phone',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Worker>>(
            stream: _service.watchWorkers(),
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('WORKERS PAGE ERROR: ${snap.error}');
                debugPrintStack(stackTrace: snap.stackTrace);

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load workers.\n\n${snap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final q = _search.text.toLowerCase();
              final list = snap.data!
                  .where(
                    (w) =>
                        w.name.toLowerCase().contains(q) || w.phone.contains(q),
                  )
                  .toList();
              if (list.isEmpty)
                return const Center(
                  child: Text('No workers yet. Tap + to add a worker.'),
                );
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final w = list[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          w.name.isEmpty ? '?' : w.name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(w.name),
                      subtitle: Text(
                        '${w.phone}\n${w.uid == null ? 'Login UID not linked' : 'Login linked'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _editWorker(worker: w);
                          if (v == 'deactivate') _deactivate(w);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _editWorker(),
      child: const Icon(Icons.add),
    ),
  );
}
