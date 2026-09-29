import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/customer_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$label berhasil disalin!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Customers',
            onPressed: () => ref.invalidate(customersProvider),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => showDialog(context: context, builder: (context) => const CreateCustomerDialog()),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('New Customer'),
            ),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          final filtered = customers.where((c) {
            if (_statusFilter != 'ALL' && c.status != _statusFilter) return false;
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.email.toLowerCase().contains(q) ||
                (c.company != null && c.company!.toLowerCase().contains(q)) ||
                (c.phone != null && c.phone!.toLowerCase().contains(q));
          }).toList();

          final totalCustomers = customers.length;
          final activeCustomers = customers.where((c) => c.status == 'ACTIVE').length;
          final licensedCount = customers.where((c) => c.licenses != null && c.licenses!.isNotEmpty).length;

          return Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari nama pelanggan, email, nomor HP, atau perusahaan...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status Filter
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'ALL', label: Text('Semua')),
                            ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                            ButtonSegment(value: 'INACTIVE', label: Text('Inactive')),
                          ],
                          selected: {_statusFilter},
                          onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      children: [
                        _buildMiniStat(context, 'Total Pelanggan', '$totalCustomers', Colors.blue),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Aktif', '$activeCustomers', Colors.green),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Punya Lisensi', '$licensedCount', Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Customer List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Belum ada data pelanggan.' : 'Pelanggan tidak ditemukan.',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Klik tombol "New Customer" untuk mendaftarkan pelanggan baru.'
                                  : 'Coba ubah kata kunci pencarian atau filter status.',
                              style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isActive = c.status == 'ACTIVE';
                          final licenses = c.licenses ?? [];

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Avatar, Name, Status & Quick Action Buttons
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                        child: Text(
                                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            if (c.company != null && c.company!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.business, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      c.company!,
                                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isActive ? Colors.green : Colors.grey).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: (isActive ? Colors.green : Colors.grey).withOpacity(0.4),
                                                ),
                                              ),
                                              child: Text(
                                                c.status,
                                                style: TextStyle(
                                                  color: isActive ? Colors.green.shade800 : Colors.grey.shade800,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (c.phone != null && c.phone!.isNotEmpty) ...[
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              icon: const Icon(Icons.chat, color: Colors.green, size: 18),
                                              tooltip: 'WhatsApp Pelanggan',
                                              onPressed: () {
                                                var clean = c.phone!.replaceAll(RegExp(r'[^0-9]'), '');
                                                if (clean.startsWith('0')) clean = '62${clean.substring(1)}';
                                                launchUrl(Uri.parse('https://wa.me/$clean'));
                                              },
                                            ),
                                            const SizedBox(width: 2),
                                          ],
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Edit Pelanggan',
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => EditCustomerDialog(customer: c),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            tooltip: 'Hapus Pelanggan',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Row(
                                                    children: [
                                                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Konfirmasi Hapus'),
                                                    ],
                                                  ),
                                                  content: Text(
                                                    'Hapus pelanggan "${c.name}"? Semua lisensi yang terhubung juga akan ikut terhapus.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, false),
                                                      child: const Text('Batal'),
                                                    ),
                                                    FilledButton(
                                                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Hapus Pelanggan'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                ref.read(customerActionProvider.notifier).deleteCustomer(c.id);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Contact Info Pills
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      _buildContactChip(
                                        context,
                                        icon: Icons.email_outlined,
                                        label: c.email,
                                        onCopy: () => _copy(c.email, 'Email'),
                                      ),
                                      if (c.phone != null && c.phone!.isNotEmpty)
                                        _buildContactChip(
                                          context,
                                          icon: Icons.phone_outlined,
                                          label: c.phone!,
                                          onCopy: () => _copy(c.phone!, 'No. Telepon'),
                                        ),
                                      _buildContactChip(
                                        context,
                                        icon: Icons.badge_outlined,
                                        label: 'ID: ${c.id.length > 8 ? c.id.substring(0, 8) : c.id}',
                                        onCopy: () => _copy(c.id, 'Customer ID'),
                                      ),
                                    ],
                                  ),

                                  // Connected Licenses
                                  if (licenses.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.vpn_key_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Lisensi (${licenses.length}):',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: licenses.map((lic) {
                                                final prodName = lic['product'] != null ? lic['product']['name'] : 'Product';
                                                final planName = lic['plan'] != null ? lic['plan']['name'] : 'Plan';
                                                final key = lic['license_key'] ?? '';
                                                final keyShort = key.length > 15 ? '${key.substring(0, 15)}...' : key;

                                                return Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '$prodName ($planName) : ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      Text(
                                                        keyShort,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontFamily: 'monospace',
                                                          fontWeight: FontWeight.w900,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      InkWell(
                                                        onTap: () => _copy(key, 'Kode Lisensi'),
                                                        child: const Padding(
                                                          padding: EdgeInsets.all(2.0),
                                                          child: Icon(Icons.copy, size: 13),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildContactChip(BuildContext context, {required IconData icon, required String label, required VoidCallback onCopy}) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
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
  final _formKey = GlobalKey<FormState>();
  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  bool isSaving = false;

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
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Register New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name / Nama Kontak *',
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pelanggan wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'e.g. customer@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number / WhatsApp',
                    hintText: 'e.g. 08123456789',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perusahaan / Toko',
                    hintText: 'e.g. Toko Makmur Jaya',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Code (Opsional)',
                    hintText: 'e.g. CUST-001',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    hintText: 'Kota, Provinsi, dll',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => isSaving = true);
                  final success = await ref.read(customerActionProvider.notifier).createCustomer(
                        codeCtrl.text.trim(),
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        phoneCtrl.text.trim(),
                        addressCtrl.text.trim(),
                        companyCtrl.text.trim(),
                      );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pelanggan berhasil didaftarkan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setState(() => isSaving = false);
                  }
                },
          child: isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Customer'),
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController companyCtrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.customer.name);
    emailCtrl = TextEditingController(text: widget.customer.email);
    phoneCtrl = TextEditingController(text: widget.customer.phone ?? '');
    addressCtrl = TextEditingController();
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
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text('Edit Customer: ${widget.customer.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company / Toko',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => isSaving = true);
                  final success = await ref.read(customerActionProvider.notifier).updateCustomer(
                        widget.customer.id,
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        phoneCtrl.text.trim(),
                        addressCtrl.text.trim(),
                        companyCtrl.text.trim(),
                      );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perubahan pelanggan berhasil disimpan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    setState(() => isSaving = false);
                  }
                },
          child: isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
