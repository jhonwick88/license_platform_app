import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plan_provider.dart';
import '../data/plan_model.dart';
import '../../products/data/product_provider.dart';
import '../../features/data/feature_provider.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plans & Features', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Plans'),
              Tab(text: 'Features'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlansTab(),
            _FeaturesTab(),
          ],
        ),
      ),
    );
  }
}

class _PlansTab extends ConsumerWidget {
  const _PlansTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (context) => const CreatePlanDialog()),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) return const Center(child: Text('No plans found.'));
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
                    DataColumn(label: Text('PRODUCT')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: plans.map((p) => DataRow(
                    cells: [
                      DataCell(Text(p.code)),
                      DataCell(Text(p.name)),
                      DataCell(Text(p.product != null ? p.product!['name'] : p.productId)),
                      DataCell(
                        Chip(
                          label: Text(p.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: p.status == 'ACTIVE' ? Colors.green : Colors.grey,
                        )
                      ),
                      DataCell(
                        FilledButton.tonalIcon(
                          onPressed: () => showDialog(context: context, builder: (context) => EditPlanFeaturesDialog(plan: p)),
                          icon: const Icon(Icons.edit_attributes, size: 18),
                          label: const Text('Edit Features'),
                        ),
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

class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(featuresProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (context) => const CreateFeatureDialog()),
        icon: const Icon(Icons.add),
        label: const Text('New Feature'),
      ),
      body: featuresAsync.when(
        data: (features) {
          if (features.isEmpty) return const Center(child: Text('No features found.'));
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
                    DataColumn(label: Text('DATA TYPE')),
                    DataColumn(label: Text('PRODUCT ID')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: features.map((f) => DataRow(
                    cells: [
                      DataCell(Text(f.code)),
                      DataCell(Text(f.name)),
                      DataCell(Text(f.dataType)),
                      DataCell(Text(f.productId)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => showDialog(context: context, builder: (context) => EditFeatureDialog(feature: f)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text('Hapus fitur ${f.code}? Paket yang menggunakannya akan kehilangan relasi fitur ini.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  ref.read(featureActionProvider.notifier).deleteFeature(f.id);
                                }
                              }
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
    for (var c in featureCtrls.values) c.dispose();
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
                  decoration: const InputDecoration(labelText: 'Select Product', helperText: 'Pilih aplikasi/produk'),
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
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Plan Code', helperText: 'Contoh: STD, PRO, ENTERPRISE')),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Plan Name', helperText: 'Contoh: Standar, Pro')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', helperText: 'Deskripsi paket ini')),
              
              if (selectedProductId != null) ...[
                const SizedBox(height: 24),
                const Text('Plan Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                featuresAsync.when(
                  data: (features) {
                    final productFeatures = features.where((f) => f.productId == selectedProductId).toList();
                    if (productFeatures.isEmpty) {
                      return const Text('Produk ini belum memiliki fitur terdaftar. Silakan tambah fitur di tab Features.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red));
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
                              hintText: 'Masukkan nilai untuk ${f.code}',
                              helperText: 'Tipe data: ${f.dataType}',
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

class CreateFeatureDialog extends ConsumerStatefulWidget {
  const CreateFeatureDialog({super.key});
  @override
  ConsumerState<CreateFeatureDialog> createState() => _CreateFeatureDialogState();
}

class _CreateFeatureDialogState extends ConsumerState<CreateFeatureDialog> {
  String? selectedProductId;
  String selectedDataType = 'NUMBER';
  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  
  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    
    return AlertDialog(
      title: const Text('Create New Feature'),
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
                  decoration: const InputDecoration(labelText: 'Select Product', helperText: 'Fitur ini akan diikat pada produk apa?'),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => selectedProductId = val),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e,st) => Text('Error loading products: $e'),
              ),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Feature Code', hintText: 'Contoh: MAX_DEVICES, HAS_API')),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Feature Name', hintText: 'Contoh: Maksimal Perangkat')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: selectedDataType,
                  decoration: const InputDecoration(labelText: 'Data Type'),
                  items: const [
                    DropdownMenuItem(value: 'NUMBER', child: Text('NUMBER (Angka)')),
                    DropdownMenuItem(value: 'BOOLEAN', child: Text('BOOLEAN (Ya/Tidak)')),
                    DropdownMenuItem(value: 'STRING', child: Text('STRING (Teks)')),
                  ],
                  onChanged: (val) => setState(() => selectedDataType = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: selectedProductId == null ? null : () async {
             final success = await ref.read(featureActionProvider.notifier).createFeature(
              selectedProductId!, codeCtrl.text, nameCtrl.text, descCtrl.text, selectedDataType
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditPlanFeaturesDialog extends ConsumerStatefulWidget {
  final Plan plan;
  const EditPlanFeaturesDialog({super.key, required this.plan});
  @override
  ConsumerState<EditPlanFeaturesDialog> createState() => _EditPlanFeaturesDialogState();
}

class _EditPlanFeaturesDialogState extends ConsumerState<EditPlanFeaturesDialog> {
  final Map<String, TextEditingController> featureCtrls = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill existing features
    if (widget.plan.planFeatures != null) {
      for (var pf in widget.plan.planFeatures!) {
        featureCtrls[pf.featureId] = TextEditingController(text: pf.value);
      }
    }
  }

  @override
  void dispose() {
    for (var c in featureCtrls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(featuresProvider);
    
    return AlertDialog(
      title: Text('Edit Features: ${widget.plan.name} (${widget.plan.code})'),
      content: SizedBox(
        width: 400,
        child: featuresAsync.when(
          data: (features) {
            final productFeatures = features.where((f) => f.productId == widget.plan.productId).toList();
            if (productFeatures.isEmpty) {
              return const Text('Produk ini belum memiliki fitur terdaftar.', style: TextStyle(color: Colors.red));
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        hintText: 'Masukkan nilai untuk ${f.code}',
                        helperText: 'Tipe data: ${f.dataType}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e,st) => Text('Error loading features: $e'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            List<Map<String, String>> updatedFeatures = [];
            featureCtrls.forEach((fId, ctrl) {
              if (ctrl.text.isNotEmpty) {
                updatedFeatures.add({'feature_id': fId, 'value': ctrl.text});
              }
            });
            
            final success = await ref.read(planActionProvider.notifier).updatePlanFeatures(
              widget.plan.id, updatedFeatures
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}


class EditFeatureDialog extends ConsumerStatefulWidget {
  final dynamic feature; // Using dynamic because Feature model might not be strictly typed in this file if we didn't import it, but it's safe since we pass 'f'. Wait, it's better to import feature_model or just use dynamic for simplicity in patching. Let's use dynamic to avoid import issues.
  const EditFeatureDialog({super.key, required this.feature});
  @override
  ConsumerState<EditFeatureDialog> createState() => _EditFeatureDialogState();
}

class _EditFeatureDialogState extends ConsumerState<EditFeatureDialog> {
  late String selectedDataType;
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  
  @override
  void initState() {
    super.initState();
    selectedDataType = widget.feature.dataType;
    nameCtrl = TextEditingController(text: widget.feature.name);
    descCtrl = TextEditingController(text: widget.feature.description ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Feature: ${widget.feature.code}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Feature Name')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                  value: selectedDataType,
                  decoration: const InputDecoration(labelText: 'Data Type'),
                  items: const [
                    DropdownMenuItem(value: 'NUMBER', child: Text('NUMBER (Angka)')),
                    DropdownMenuItem(value: 'BOOLEAN', child: Text('BOOLEAN (Ya/Tidak)')),
                    DropdownMenuItem(value: 'STRING', child: Text('STRING (Teks)')),
                  ],
                  onChanged: (val) => setState(() => selectedDataType = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
             final success = await ref.read(featureActionProvider.notifier).updateFeature(
              widget.feature.id, nameCtrl.text, descCtrl.text, selectedDataType
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
