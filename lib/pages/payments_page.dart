import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/worker.dart';
import '../services/payment_service.dart';
import '../services/worker_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key, this.workerMode = false});
  final bool workerMode;
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _payments = PaymentService();
  final _workers = WorkerService();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _workerId;
  String _type = 'Salary';
  String _method = 'Cash';
  bool _approved = true;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double _signed(PaymentTransaction t) =>
      ['Debit', 'Advance'].contains(t.type) ? -t.amount : t.amount;
  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  Future<void> _add(List<Worker> workers) async {
    if (workers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a worker first.')));
      return;
    }
    _amount.clear();
    _note.clear();
    _workerId = workers.first.id;
    _type = 'Salary';
    _method = 'Cash';
    _approved = true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _workerId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Worker'),
                  items: workers
                      .map(
                        (w) =>
                            DropdownMenuItem(value: w.id, child: Text(w.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => _workerId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items:
                      const ['Salary', 'Advance', 'Credit', 'Debit', 'Deposit']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setDialog(() => _type = v ?? 'Salary'),
                ),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                ),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                DropdownButtonFormField<String>(
                  value: _method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const ['Cash', 'Bank', 'UPI']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setDialog(() => _method = v ?? 'Cash'),
                ),
                SwitchListTile(
                  title: const Text('Approved for worker'),
                  value: _approved,
                  onChanged: (v) => setDialog(() => _approved = v),
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
              onPressed: () async {
                final matches = workers
                    .where((w) => w.id == _workerId)
                    .toList();
                final worker = matches.isEmpty ? null : matches.first;
                final amount = double.tryParse(_amount.text.trim());
                if (worker == null || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Select a worker and enter a valid amount.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _payments.addTransaction(
                    worker: worker,
                    type: _type,
                    amount: amount,
                    method: _method,
                    note: _note.text,
                    approved: _approved,
                  );
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction saved.')),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save transaction: $e')),
                    );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workerMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Approved Payments')),
        body: StreamBuilder<List<PaymentTransaction>>(
          stream: _payments.watchMyApprovedTransactions(),
          builder: (context, snap) {
            if (snap.hasError)
              return const Center(
                child: Text('Could not load approved payments.'),
              );
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            final balance = list.fold<double>(0, (sum, t) => sum + _signed(t));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Net approved balance'),
                    titleTextStyle: Theme.of(context).textTheme.titleMedium,
                    subtitle: Text(
                      _money(balance),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...list.map(
                  (t) => Card(
                    child: ListTile(
                      title: Text('${t.type} • ${_money(t.amount)}'),
                      subtitle: Text(
                        '${t.note}\n${t.date.toLocal().toString().split(' ').first} • ${t.method}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: StreamBuilder<List<Worker>>(
        stream: _workers.watchWorkers(),
        builder: (context, workerSnap) {
          if (workerSnap.hasError)
            return const Center(child: Text('Could not load workers.'));
          if (!workerSnap.hasData)
            return const Center(child: CircularProgressIndicator());
          final workers = workerSnap.data!;
          return StreamBuilder<List<PaymentTransaction>>(
            stream: _payments.watchTransactions(),
            builder: (context, txSnap) {
              if (txSnap.hasError)
                return const Center(
                  child: Text(
                    'Could not load transactions. Check Firestore rules/indexes.',
                  ),
                );
              if (!txSnap.hasData)
                return const Center(child: CircularProgressIndicator());
              final list = txSnap.data!;
              final total = list.fold<double>(0, (s, t) => s + _signed(t));
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: const Text('Net ledger total'),
                      subtitle: Text(
                        _money(total),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _add(workers),
                        icon: const Icon(Icons.add_circle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No transactions yet. Tap + to add one.'),
                      ),
                    ),
                  ...list.map(
                    (t) => Card(
                      child: ListTile(
                        leading: Icon(
                          ['Debit', 'Advance'].contains(t.type)
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: ['Debit', 'Advance'].contains(t.type)
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                        title: Text('${t.workerName} • ${t.type}'),
                        subtitle: Text(
                          '${t.note}\n${t.date.toLocal().toString().split(' ').first} • ${t.method} • ${t.approved ? 'Approved' : 'Pending approval'}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _money(_signed(t)),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final workers = await _workers.watchWorkers().first;
          if (mounted) _add(workers);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
