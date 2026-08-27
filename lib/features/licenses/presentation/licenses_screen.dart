import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/license_provider.dart';
import '../../customers/data/customer_provider.dart';
import '../../products/data/product_provider.dart';
import '../../plans/data/plan_provider.dart';

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
              onPressed: () => showDialog(context: context, builder: (context) => const CreateLicenseDialog()),
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
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('PRODUCT / PLAN')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: licenses.map((l) {
                    final custName = l.customer != null ? l.customer!['name'] : l.customerId;
                    final prodName = l.product != null ? l.product!['name'] : l.productId;
                    final planName = l.plan != null ? l.plan!['name'] : l.planId;
                    
                    return DataRow(
                      cells: [
                        DataCell(SelectableText(l.licenseKey, style: const TextStyle(fontFamily: 'monospace'))),
                        DataCell(Text(custName.toString())),
                        DataCell(Text('$prodName\n($planName)')),
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
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text('Hapus lisensi ${l.licenseKey} permanen?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    ref.read(licenseActionProvider.notifier).deleteLicense(l.id);
                                  }
                                }
                              ),
                            ],
                          )
                        ),
                      ]
                    );
                  }).toList(),
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
}

class CreateLicenseDialog extends ConsumerStatefulWidget {
  const CreateLicenseDialog({super.key});
  @override
  ConsumerState<CreateLicenseDialog> createState() => _CreateLicenseDialogState();
}

class _CreateLicenseDialogState extends ConsumerState<CreateLicenseDialog> {
  String? selectedCustomerId;
  String? selectedProductId;
  String? selectedPlanId;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);
    final plansAsync = ref.watch(plansProvider);

    return AlertDialog(
      title: const Text('Generate New License'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customersAsync.when(
              data: (customers) => DropdownButtonFormField<String>(
                value: selectedCustomerId,
                decoration: const InputDecoration(labelText: 'Select Customer', helperText: 'Pilih pelanggan'),
                items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => selectedCustomerId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error loading customers: $e'),
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) => DropdownButtonFormField<String>(
                value: selectedProductId,
                decoration: const InputDecoration(labelText: 'Select Product', helperText: 'Pilih produk aplikasi'),
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedProductId = val;
                    selectedPlanId = null; // reset plan
                  });
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error loading products: $e'),
            ),
            const SizedBox(height: 16),
            if (selectedProductId != null)
              plansAsync.when(
                data: (plans) {
                  final filteredPlans = plans.where((p) => p.productId == selectedProductId).toList();
                  if (filteredPlans.isEmpty) {
                    return const Text('Produk ini belum memiliki paket (Plan). Silakan buat paket terlebih dahulu.', style: TextStyle(color: Colors.red));
                  }
                  return DropdownButtonFormField<String>(
                    value: selectedPlanId,
                    decoration: const InputDecoration(labelText: 'Select Plan', helperText: 'Pilih paket lisensi'),
                    items: filteredPlans.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (val) => setState(() => selectedPlanId = val),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading plans: $e'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: (selectedCustomerId == null || selectedProductId == null || selectedPlanId == null) ? null : () async {
            final success = await ref.read(licenseActionProvider.notifier).createLicense(
              selectedCustomerId!, selectedProductId!, selectedPlanId!
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

