import 'package:flutter/material.dart';

import '../models/worker.dart';
import '../services/worker_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final WorkerService workerService = WorkerService.instance;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedWorkerId = 'WK001';
  String selectedType = 'Credit';
  String selectedMethod = 'Cash';

  final List<Map<String, dynamic>> transactions = [
    {
      'workerId': 'WK001',
      'name': 'Rahul Patel',
      'type': 'Credit',
      'amount': 5000.0,
      'method': 'Bank',
      'note': 'Monthly salary',
      'date': DateTime.now(),
    },
    {
      'workerId': 'WK002',
      'name': 'Amit Shah',
      'type': 'Debit',
      'amount': 1000.0,
      'method': 'Cash',
      'note': 'Advance payment',
      'date': DateTime.now(),
    },
    {
      'workerId': 'WK003',
      'name': 'Vijay Parmar',
      'type': 'Credit',
      'amount': 2500.0,
      'method': 'UPI',
      'note': 'Payment',
      'date': DateTime.now(),
    },
  ];

  @override
  void initState() {
    super.initState();
    workerService.addListener(_onWorkersChanged);
  }

  void _onWorkersChanged() {
    if (!mounted) return;

    setState(() {
      if (workerService.findById(selectedWorkerId) == null &&
          workerService.workers.isNotEmpty) {
        selectedWorkerId = workerService.workers.first.id;
      }
    });
  }

  @override
  void dispose() {
    workerService.removeListener(_onWorkersChanged);
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double get totalCredit => transactions
      .where((transaction) => transaction['type'] == 'Credit')
      .fold<double>(
        0,
        (total, transaction) =>
            total + (transaction['amount'] as num).toDouble(),
      );

  double get totalDebit => transactions
      .where((transaction) => transaction['type'] == 'Debit')
      .fold<double>(
        0,
        (total, transaction) =>
            total + (transaction['amount'] as num).toDouble(),
      );

  double get balance => totalCredit - totalDebit;

  String money(double amount) => '₹${amount.toStringAsFixed(2)}';

  Color typeColor(String type) {
    return type == 'Credit' ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
  }

  void showAddTransactionDialog() {
    if (workerService.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a worker before adding a payment.'),
        ),
      );
      return;
    }

    amountController.clear();
    noteController.clear();

    if (workerService.findById(selectedWorkerId) == null) {
      selectedWorkerId = workerService.workers.first.id;
    }

    selectedType = 'Credit';
    selectedMethod = 'Cash';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151D32),
              title: const Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedWorkerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Worker',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: workerService.workers.map((worker) {
                        return DropdownMenuItem<String>(
                          value: worker.id,
                          child: Text(
                            worker.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedWorkerId = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Credit',
                          child: Text('Credit (Money In)'),
                        ),
                        DropdownMenuItem(
                          value: 'Debit',
                          child: Text('Debit (Money Out)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(
                          value: 'Bank',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedMethod = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'e.g. Monthly salary',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amountText = amountController.text.trim();
                    final amount = double.tryParse(amountText);

                    if (amount == null || !amount.isFinite || amount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid amount greater than zero.',
                          ),
                        ),
                      );
                      return;
                    }

                    final Worker? worker = workerService.findById(
                      selectedWorkerId,
                    );

                    if (worker == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a valid worker.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      transactions.insert(0, {
                        'workerId': worker.id,
                        'name': worker.name,
                        'type': selectedType,
                        'amount': amount,
                        'method': selectedMethod,
                        'note': noteController.text.trim().isEmpty
                            ? 'No note'
                            : noteController.text.trim(),
                        'date': DateTime.now(),
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction added successfully.'),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: showAddTransactionDialog,
            icon: const Icon(Icons.add_card),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Current Balance',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    money(balance),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Total credit minus total debit',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Credit',
                    amount: money(totalCredit),
                    color: const Color(0xFF22C55E),
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Debit',
                    amount: money(totalDebit),
                    color: const Color(0xFFEF4444),
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${transactions.length} records',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No transactions available.')),
              )
            else
              ...transactions.map((transaction) {
                final type = transaction['type'] as String;
                final color = typeColor(type);
                final date = transaction['date'] as DateTime;
                final workerId = transaction['workerId'] as String;
                final currentWorker = workerService.findById(workerId);
                final workerName =
                    currentWorker?.name ?? transaction['name'] as String;
                final amount = (transaction['amount'] as num).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151D32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.14),
                        child: Icon(
                          type == 'Credit'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction['note']}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}/'
                              '${date.year} • ${transaction['method']}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${type == 'Credit' ? '+' : '-'}${money(amount)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            type,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151D32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            amount,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
