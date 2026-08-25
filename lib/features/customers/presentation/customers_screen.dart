import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Customer'),
            ),
          )
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return Card(
            margin: const EdgeInsets.all(24),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('CODE')),
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('EMAIL')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: customers.map((c) => DataRow(
                    cells: [
                      DataCell(Text(c.customerCode)),
                      DataCell(Text(c.name)),
                      DataCell(Text(c.email ?? '-')),
                      DataCell(
                        Chip(
                          label: Text(c.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: c.status == 'ACTIVE' ? Colors.green : Colors.grey,
                        )
                      ),
                    ]
                  )).toList(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Customer'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Customer Code')),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final success = await ref.read(customerActionProvider.notifier).createCustomer(
                codeCtrl.text, nameCtrl.text, emailCtrl.text
              );
              if (success && context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
