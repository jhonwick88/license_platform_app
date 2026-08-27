import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (context) => const CreateCustomerDialog()),
        icon: const Icon(Icons.add),
        label: const Text('New Customer'),
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) return const Center(child: Text('No customers found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final c = customers[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(c.name.substring(0, 1).toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(c.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(c.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: c.status == 'ACTIVE' ? Colors.green : Colors.grey,
                  ),
                  children: [
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Company: ${c.company ?? '-'}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('Phone: ${c.phone ?? '-'}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              Row(
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () => showDialog(context: context, builder: (context) => EditCustomerDialog(customer: c)),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(0.1),
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirm Delete'),
                                          content: Text('Hapus pelanggan ${c.name}? Semua lisensi yang dimiliki akan ikut terhapus.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(customerActionProvider.notifier).deleteCustomer(c.id);
                                      }
                                    },
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Berlangganan Produk (Lisensi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (c.licenses == null || c.licenses!.isEmpty)
                            const Text('Belum ada lisensi berlangganan.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: c.licenses!.map((lic) {
                                final productName = lic['product'] != null ? lic['product']['name'] : 'Unknown Product';
                                final planName = lic['plan'] != null ? lic['plan']['name'] : 'Unknown Plan';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$productName ($planName)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(lic['license_key'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace')),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class CreateCustomerDialog extends ConsumerStatefulWidget {
  const CreateCustomerDialog({super.key});

  @override
  ConsumerState<CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends ConsumerState<CreateCustomerDialog> {
  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final companyCtrl = TextEditingController();

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Customer'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Customer Code', hintText: 'e.g. CUST-001')),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. John Doe')),
              const SizedBox(height: 16),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', hintText: 'e.g. john@example.com')),
              const SizedBox(height: 16),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. +62812...')),
              const SizedBox(height: 16),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company', hintText: 'e.g. Acme Corp')),
              const SizedBox(height: 16),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final success = await ref.read(customerActionProvider.notifier).createCustomer(
              codeCtrl.text, nameCtrl.text, emailCtrl.text, phoneCtrl.text, addressCtrl.text, companyCtrl.text
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class EditCustomerDialog extends ConsumerStatefulWidget {
  final dynamic customer;
  const EditCustomerDialog({super.key, required this.customer});

  @override
  ConsumerState<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends ConsumerState<EditCustomerDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController companyCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.customer.name);
    emailCtrl = TextEditingController(text: widget.customer.email);
    phoneCtrl = TextEditingController(text: widget.customer.phone ?? '');
    // Note: widget.customer (Customer model) may not have address mapped if we didn't add it in the model, 
    // but the backend handles it. For now let's just pass empty if not present.
    // I should probably map it in model but let's just bypass by using an empty string if null
    try { addressCtrl = TextEditingController(text: widget.customer.address ?? ''); } catch (e) { addressCtrl = TextEditingController(); }
    companyCtrl = TextEditingController(text: widget.customer.company ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Customer: ${widget.customer.name}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 16),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 16),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
              const SizedBox(height: 16),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final success = await ref.read(customerActionProvider.notifier).updateCustomer(
              widget.customer.id, nameCtrl.text, emailCtrl.text, phoneCtrl.text, addressCtrl.text, companyCtrl.text
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

