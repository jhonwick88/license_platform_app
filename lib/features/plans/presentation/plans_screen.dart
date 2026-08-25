import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plan_provider.dart';
import '../../products/data/product_provider.dart';
import '../../features/data/feature_provider.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => showDialog(context: context, builder: (context) => const CreatePlanDialog()),
              icon: const Icon(Icons.add),
              label: const Text('New Plan'),
            ),
          )
        ],
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No plans found.'));
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
                    DataColumn(label: Text('PRODUCT ID')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: plans.map((p) => DataRow(
                    cells: [
                      DataCell(Text(p.code)),
                      DataCell(Text(p.name)),
                      DataCell(Text(p.productId)),
                      DataCell(
                        Chip(
                          label: Text(p.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: p.status == 'ACTIVE' ? Colors.green : Colors.grey,
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
}

class CreatePlanDialog extends ConsumerStatefulWidget {
  const CreatePlanDialog({super.key});
  @override
  ConsumerState<CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends ConsumerState<CreatePlanDialog> {
  String? selectedProductId;
  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  
  final Map<String, TextEditingController> featureCtrls = {};

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    for (var c in featureCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final featuresAsync = ref.watch(featuresProvider);
    
    return AlertDialog(
      title: const Text('Create New Plan'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productsAsync.when(
                data: (products) => DropdownButtonFormField<String>(
                  value: selectedProductId,
                  decoration: const InputDecoration(labelText: 'Select Product'),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedProductId = val;
                      featureCtrls.clear();
                    });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e,st) => Text('Error loading products: $e'),
              ),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Plan Code')),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Plan Name')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              
              if (selectedProductId != null) ...[
                const SizedBox(height: 24),
                const Text('Plan Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                featuresAsync.when(
                  data: (features) {
                    final productFeatures = features.where((f) => f.productId == selectedProductId).toList();
                    if (productFeatures.isEmpty) {
                      return const Text('No features for this product.', style: TextStyle(fontStyle: FontStyle.italic));
                    }
                    return Column(
                      children: productFeatures.map((f) {
                        if (!featureCtrls.containsKey(f.id)) {
                          featureCtrls[f.id] = TextEditingController();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            controller: featureCtrls[f.id],
                            decoration: InputDecoration(
                              labelText: f.name,
                              hintText: 'Enter value for ${f.code}',
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e,st) => Text('Error loading features: $e'),
                )
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: selectedProductId == null ? null : () async {
            List<Map<String, String>> planFeatures = [];
            featureCtrls.forEach((fId, ctrl) {
              if (ctrl.text.isNotEmpty) {
                planFeatures.add({'feature_id': fId, 'value': ctrl.text});
              }
            });
            
            final success = await ref.read(planActionProvider.notifier).createPlan(
              selectedProductId!, codeCtrl.text, nameCtrl.text, descCtrl.text, planFeatures
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
