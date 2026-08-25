import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/license_provider.dart';

class LicensesScreen extends ConsumerWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licensesAsync = ref.watch(licensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Generate License'),
            ),
          )
        ],
      ),
      body: licensesAsync.when(
        data: (licenses) {
          if (licenses.isEmpty) {
            return const Center(child: Text('No licenses found.'));
          }
          return Card(
            margin: const EdgeInsets.all(24),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('LICENSE KEY')),
                    DataColumn(label: Text('PRODUCT / PLAN (IDs)')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: licenses.map((l) => DataRow(
                    cells: [
                      DataCell(SelectableText(l.licenseKey, style: const TextStyle(fontFamily: 'monospace'))),
                      DataCell(Text('P: ${l.productId}\nPL: ${l.planId}')),
                      DataCell(
                        Chip(
                          label: Text(l.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: _getStatusColor(l.status),
                        )
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (l.status != 'SUSPENDED' && l.status != 'REVOKED')
                              IconButton(
                                icon: const Icon(Icons.pause_circle, size: 20, color: Colors.orange),
                                tooltip: 'Suspend',
                                onPressed: () => ref.read(licenseActionProvider.notifier).changeStatus(l.id, 'suspend'),
                              ),
                            if (l.status == 'SUSPENDED')
                              IconButton(
                                icon: const Icon(Icons.play_circle, size: 20, color: Colors.green),
                                tooltip: 'Resume',
                                onPressed: () => ref.read(licenseActionProvider.notifier).changeStatus(l.id, 'resume'),
                              ),
                            if (l.status != 'REVOKED')
                              IconButton(
                                icon: const Icon(Icons.block, size: 20, color: Colors.red),
                                tooltip: 'Revoke',
                                onPressed: () => ref.read(licenseActionProvider.notifier).changeStatus(l.id, 'revoke'),
                              ),
                          ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE': return Colors.green;
      case 'PENDING': return Colors.blueGrey;
      case 'SUSPENDED': return Colors.orange;
      case 'REVOKED': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final customerCtrl = TextEditingController();
    final productCtrl = TextEditingController();
    final planCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate New License'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: customerCtrl, decoration: const InputDecoration(labelText: 'Customer ID', helperText: 'Requires existing UUID')),
              const SizedBox(height: 16),
              TextField(controller: productCtrl, decoration: const InputDecoration(labelText: 'Product ID')),
              const SizedBox(height: 16),
              TextField(controller: planCtrl, decoration: const InputDecoration(labelText: 'Plan ID')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final success = await ref.read(licenseActionProvider.notifier).createLicense(
                customerCtrl.text, productCtrl.text, planCtrl.text
              );
              if (success && context.mounted) Navigator.pop(context);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
