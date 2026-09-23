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

// ==========================================
// PLANS TAB (DENGAN FILTER PRODUK)
// ==========================================
class _PlansTab extends ConsumerStatefulWidget {
  const _PlansTab();

  @override
  ConsumerState<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends ConsumerState<_PlansTab> {
  String? _selectedProductId; // null = Semua Produk

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(context: context, builder: (context) => const CreatePlanDialog()),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) return const Center(child: Text('No plans found.'));

          return productsAsync.when(
            data: (products) {
              final productMap = {for (var p in products) p.id: p.name};

              final filteredPlans = _selectedProductId == null
                  ? plans
                  : plans.where((p) => p.productId == _selectedProductId).toList();

              return Column(
                children: [
                  // Filter Bar by Product
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Produk:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text('Semua Produk (${plans.length})'),
                            selected: _selectedProductId == null,
                            onSelected: (_) => setState(() => _selectedProductId = null),
                          ),
                          const SizedBox(width: 8),
                          ...products.map((prod) {
                            final count = plans.where((p) => p.productId == prod.id).length;
                            final isSelected = _selectedProductId == prod.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.storefront_rounded,
                                  size: 16,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700],
                                ),
                                label: Text('${prod.name} ($count)'),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedProductId = prod.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Plans List
                  Expanded(
                    child: filteredPlans.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Tidak ada paket langganan untuk produk ini.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filteredPlans.length,
                            itemBuilder: (context, index) {
                              final p = filteredPlans[index];
                              final productName = p.product != null
                                  ? p.product!['name']
                                  : (productMap[p.productId] ?? p.productId);

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.category_outlined, size: 13, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              productName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      p.description ?? 'Tidak ada deskripsi',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Chip(
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    label: Text(p.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: p.status == 'ACTIVE' ? Colors.green : Colors.grey,
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.04),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Plan Features & Limits',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              FilledButton.tonalIcon(
                                                onPressed: () => showDialog(
                                                  context: context,
                                                  builder: (context) => EditPlanFeaturesDialog(plan: p),
                                                ),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: const Text('Edit Features'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          if (p.planFeatures == null || p.planFeatures!.isEmpty)
                                            const Text(
                                              'Tidak ada fitur terdaftar untuk paket ini.',
                                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                            )
                                          else
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: p.planFeatures!.map((pf) {
                                                final featureName = pf.feature != null
                                                    ? pf.feature!['name']
                                                    : pf.featureId;
                                                final featureCode = pf.feature != null
                                                    ? pf.feature!['code']
                                                    : null;

                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surface,
                                                    border: Border.all(color: Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        featureName,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade600,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      if (featureCode != null)
                                                        Text(
                                                          featureCode,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey.shade500,
                                                            fontFamily: 'monospace',
                                                          ),
                                                        ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        pf.value,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Colors.teal,
                                                        ),
                                                      ),
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
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading products: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ==========================================
// FEATURES TAB (DIKELOMPOKKAN PER PRODUK)
// ==========================================
class _FeaturesTab extends ConsumerStatefulWidget {
  const _FeaturesTab();

  @override
  ConsumerState<_FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends ConsumerState<_FeaturesTab> {
  String? _selectedProductId; // null = Semua Produk
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(featuresProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => CreateFeatureDialog(preSelectedProductId: _selectedProductId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Feature'),
      ),
      body: featuresAsync.when(
        data: (features) {
          if (features.isEmpty) {
            return const Center(child: Text('Belum ada fitur terdaftar. Silakan buat fitur baru.'));
          }

          return productsAsync.when(
            data: (products) {
              final productMap = {for (var p in products) p.id: p.name};

              // Filter features based on query and product
              final filteredFeatures = features.where((f) {
                final matchProduct = _selectedProductId == null || f.productId == _selectedProductId;
                final matchQuery = _searchQuery.isEmpty ||
                    f.code.toLowerCase().contains(_searchQuery) ||
                    f.name.toLowerCase().contains(_searchQuery) ||
                    (f.description ?? '').toLowerCase().contains(_searchQuery);
                return matchProduct && matchQuery;
              }).toList();

              // Group features by Product
              final productsToShow = _selectedProductId == null
                  ? products
                  : products.where((p) => p.id == _selectedProductId).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Bar & Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari kode / nama fitur...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Product filter chips
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: Text('Semua Produk (${features.length})'),
                                  selected: _selectedProductId == null,
                                  onSelected: (_) => setState(() => _selectedProductId = null),
                                ),
                                const SizedBox(width: 8),
                                ...products.map((prod) {
                                  final count = features.where((f) => f.productId == prod.id).length;
                                  final isSelected = _selectedProductId == prod.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      avatar: Icon(
                                        Icons.storefront_rounded,
                                        size: 16,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700],
                                      ),
                                      label: Text('${prod.name} ($count)'),
                                      selected: isSelected,
                                      onSelected: (_) => setState(() => _selectedProductId = prod.id),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Content List grouped by Product
                  Expanded(
                    child: filteredFeatures.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Tidak ada fitur yang cocok dengan pencarian/filter.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: productsToShow.length,
                            itemBuilder: (context, index) {
                              final prod = productsToShow[index];
                              final prodFeatures = filteredFeatures.where((f) => f.productId == prod.id).toList();

                              if (prodFeatures.isEmpty && _searchQuery.isNotEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.18)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Header Banner
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          topRight: Radius.circular(14),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_rounded,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prod.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(
                                                  'Product Code: ${prod.productCode}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${prodFeatures.length} Fitur Terdaftar',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                            icon: const Icon(Icons.add, size: 18),
                                            tooltip: 'Tambah Fitur untuk ${prod.name}',
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => CreateFeatureDialog(preSelectedProductId: prod.id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),

                                    // Features Table
                                    if (prodFeatures.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Produk ini belum memiliki fitur. Klik tombol + untuk menambahkan fitur.',
                                              style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.04)),
                                          columns: const [
                                            DataColumn(label: Text('KODE FITUR (KEY)', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('NAMA FITUR', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('TIPE DATA', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('DESKRIPSI', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: prodFeatures.map((f) {
                                            return DataRow(
                                              cells: [
                                                // Kode Fitur
                                                DataCell(
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.grey.shade300),
                                                    ),
                                                    child: Text(
                                                      f.code,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Nama Fitur
                                                DataCell(
                                                  Text(
                                                    f.name,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                                  ),
                                                ),
                                                // Tipe Data
                                                DataCell(_buildDataTypeBadge(f.dataType)),
                                                // Deskripsi
                                                DataCell(
                                                  SizedBox(
                                                    width: 250,
                                                    child: Text(
                                                      f.description?.isNotEmpty == true ? f.description! : '-',
                                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ),
                                                // Aksi
                                                DataCell(
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                                        tooltip: 'Edit Fitur',
                                                        onPressed: () => showDialog(
                                                          context: context,
                                                          builder: (context) => EditFeatureDialog(feature: f),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                        tooltip: 'Hapus Fitur',
                                                        onPressed: () => _confirmDeleteFeature(context, f),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading products: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDataTypeBadge(String dataType) {
    Color bg;
    Color fg;
    IconData icon;

    switch (dataType.toUpperCase()) {
      case 'BOOLEAN':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.toggle_on_outlined;
        break;
      case 'NUMBER':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        icon = Icons.numbers_rounded;
        break;
      case 'STRING':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        icon = Icons.text_fields_rounded;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        icon = Icons.label_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            dataType.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFeature(BuildContext context, dynamic f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Fitur'),
        content: Text(
          'Hapus fitur "${f.name}" (${f.code})?\nPaket yang menggunakan fitur ini akan kehilangan relasi datanya.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(featureActionProvider.notifier).deleteFeature(f.id);
    }
  }
}

// ==========================================
// DIALOGS
// ==========================================
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
  
  Map<String, TextEditingController> featureCtrls = {};

  @override
  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    featureCtrls.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final featuresAsync = ref.watch(featuresProvider);

    return AlertDialog(
      title: const Text('Create New Plan'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productsAsync.when(
                data: (products) => DropdownButtonFormField<String>(
                  value: selectedProductId,
                  decoration: const InputDecoration(labelText: 'Select Product', helperText: 'Pilih produk untuk paket ini'),
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
                              labelText: '${f.name} (${f.code})',
                              helperText: 'Tipe data: ${f.dataType}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                  error: (e,st) => Text('Error loading features: $e'),
                ),
              ],
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
          child: const Text('Save Plan'),
        ),
      ],
    );
  }
}

class CreateFeatureDialog extends ConsumerStatefulWidget {
  final String? preSelectedProductId;
  const CreateFeatureDialog({super.key, this.preSelectedProductId});

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
  void initState() {
    super.initState();
    selectedProductId = widget.preSelectedProductId;
  }

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
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productsAsync.when(
                data: (products) => DropdownButtonFormField<String>(
                  value: selectedProductId,
                  decoration: const InputDecoration(labelText: 'Select Product *', helperText: 'Fitur ini akan diikat pada produk apa?'),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => selectedProductId = val),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e,st) => Text('Error loading products: $e'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Feature Code (Key) *',
                  hintText: 'Contoh: max_cashiers, sales_reports',
                  helperText: 'Kunci teknis yang diperiksa di kode program client',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Feature Name *',
                  hintText: 'Contoh: Maksimal Kasir, Laporan Penjualan',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (Opsional)',
                  hintText: 'Penjelasan kegunaan fitur ini',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDataType,
                decoration: const InputDecoration(labelText: 'Data Type *'),
                items: const [
                  DropdownMenuItem(value: 'NUMBER', child: Text('NUMBER (Angka, misal: 5)')),
                  DropdownMenuItem(value: 'BOOLEAN', child: Text('BOOLEAN (Ya/Tidak, misal: true/false)')),
                  DropdownMenuItem(value: 'STRING', child: Text('STRING (Teks, misal: Standar)')),
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
            if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
              return;
            }
            final success = await ref.read(featureActionProvider.notifier).createFeature(
              selectedProductId!, codeCtrl.text.trim(), nameCtrl.text.trim(), descCtrl.text.trim(), selectedDataType
            );
            if (success && context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Feature'),
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
  Map<String, TextEditingController> featureCtrls = {};

  @override
  void initState() {
    super.initState();
    if (widget.plan.planFeatures != null) {
      for (var pf in widget.plan.planFeatures!) {
        featureCtrls[pf.featureId] = TextEditingController(text: pf.value);
      }
    }
  }

  @override
  void dispose() {
    featureCtrls.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(featuresProvider);

    return AlertDialog(
      title: Text('Edit Features: ${widget.plan.name} (${widget.plan.code})'),
      content: SizedBox(
        width: 500,
        child: featuresAsync.when(
          data: (features) {
            final productFeatures = features.where((f) => f.productId == widget.plan.productId).toList();
            if (productFeatures.isEmpty) {
              return const Text('Produk ini belum memiliki fitur terdaftar. Silakan buat fitur terlebih dahulu di tab Features.', style: TextStyle(color: Colors.red));
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
                        labelText: '${f.name} (${f.code})',
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
  final dynamic feature;
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
