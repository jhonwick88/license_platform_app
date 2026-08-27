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
        title: const Text('Customers Management', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    DataColumn(label: Text('PHONE')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: customers.map((c) => DataRow(
                    cells: [
                      DataCell(Text(c.customerCode)),
                      DataCell(Text(c.name)),
                      DataCell(Text(c.email ?? '')),
                      DataCell(Text(c.phone ?? '')),
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
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Customer'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Customer Code',
                    hintText: 'Contoh: CUST-001',
                    helperText: 'ID unik untuk pelanggan',
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Contoh: PT. Sumber Makmur',
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'admin@sumbermakmur.com',
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '081234567890',
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addrCtrl, 
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Jl. Merdeka No.1',
                  )
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final success = await ref.read(customerActionProvider.notifier).createCustomer(
                codeCtrl.text, nameCtrl.text, emailCtrl.text, phoneCtrl.text, addrCtrl.text
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

