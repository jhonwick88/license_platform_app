import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/license_model.dart';
import '../data/license_provider.dart';
import '../../customers/data/customer_provider.dart';
import '../../products/data/product_provider.dart';
import '../../plans/data/plan_provider.dart';
import '../../plans/data/plan_model.dart';

class LicensesScreen extends ConsumerStatefulWidget {
  const LicensesScreen({super.key});

  @override
  ConsumerState<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends ConsumerState<LicensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, ACTIVE, PENDING, SUSPENDED, REVOKED
  String? _selectedProductId; // null = Semua Produk

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String successMessage) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(successMessage)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatLicenseShareText(License license, Plan? plan) {
    final custName = license.customer != null ? license.customer!['name'] : license.customerId;
    final companyName = license.customer?['company_name'] ?? license.customer?['company'];
    final phone = license.customer?['phone'];
    final prodName = license.product != null ? license.product!['name'] : license.productId;
    final planName = license.plan != null ? license.plan!['name'] : (plan?.name ?? license.planId);

    final sb = StringBuffer();
    sb.writeln('🔑 *INFORMASI LISENSI PINTAR LABS*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('👤 *Pelanggan*   : $custName${companyName != null && companyName.toString().isNotEmpty ? ' ($companyName)' : ''}');
    if (phone != null && phone.toString().trim().isNotEmpty) {
      sb.writeln('📱 *Kontak*      : $phone');
    }
    sb.writeln('📦 *Aplikasi*    : $prodName');
    sb.writeln('🏷️ *Paket Plan*  : $planName');
    sb.writeln('⚡ *Status*      : ${license.status}');
    sb.writeln('');
    sb.writeln('🔑 *KODE LISENSI (LICENSE KEY)*:');
    sb.writeln(license.licenseKey);
    sb.writeln('');

    // Feature list
    List<PlanFeature>? features = plan?.planFeatures;
    if (features == null && license.plan != null && license.plan!['plan_features'] != null) {
      final rawList = license.plan!['plan_features'] as List?;
      features = rawList?.map((e) => PlanFeature.fromJson(e)).toList();
    }

    if (features != null && features.isNotEmpty) {
      sb.writeln('✨ *Fitur & Batasan yang Diaktifkan*:');
      for (final f in features) {
        final fName = f.feature != null ? f.feature!['name'] : f.featureId;
        final fVal = f.value.toLowerCase() == 'true'
            ? 'Aktif'
            : (f.value.toLowerCase() == 'false' ? 'Tidak Aktif' : f.value);
        sb.writeln('  • $fName : $fVal');
      }
      sb.writeln('');
    }

    final dateStr = '${license.createdAt.day.toString().padLeft(2, '0')}-${license.createdAt.month.toString().padLeft(2, '0')}-${license.createdAt.year}';
    sb.writeln('📅 *Tanggal Dibuat*: $dateStr');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('💡 *Petunjuk Aktivasi*:');
    sb.writeln('1. Buka aplikasi $prodName pada komputer/perangkat Anda.');
    sb.writeln('2. Masuk ke menu Aktivasi Lisensi.');
    sb.writeln('3. Masukkan Kode Lisensi di atas, lalu klik "Aktivasi".');
    sb.writeln('Simpan informasi ini sebagai bukti kepemilikan lisensi resmi Anda.');

    return sb.toString();
  }

  void _shareLicense(License license, Plan? plan) {
    final shareText = _formatLicenseShareText(license, plan);
    _copyToClipboard(shareText, 'Format informasi lisensi lengkap disalin ke clipboard!');

    // Show preview and direct WhatsApp sharing modal
    showDialog(
      context: context,
      builder: (ctx) => _SharePreviewDialog(
        license: license,
        shareText: shareText,
        onCopy: () => _copyToClipboard(shareText, 'Informasi lisensi disalin!'),
      ),
    );
  }

  void _showLicenseDetail(License license, Plan? plan) {
    showDialog(
      context: context,
      builder: (ctx) => _LicenseDetailDialog(
        license: license,
        plan: plan,
        onShare: () => _shareLicense(license, plan),
        onCopyKey: () => _copyToClipboard(license.licenseKey, 'License key disalin!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final licensesAsync = ref.watch(licensesProvider);
    final productsAsync = ref.watch(productsProvider);
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: () => ref.invalidate(licensesProvider),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: FilledButton.icon(
              onPressed: () => showDialog(context: context, builder: (context) => const CreateLicenseDialog()),
              icon: const Icon(Icons.add),
              label: const Text('Generate License'),
            ),
          ),
        ],
      ),
      body: licensesAsync.when(
        data: (licenses) {
          final plansMap = plansAsync.asData?.value ?? [];

          // 1. Calculate KPI Metrics
          final totalLicenses = licenses.length;
          final activeCount = licenses.where((l) => l.status == 'ACTIVE').length;
          final pendingCount = licenses.where((l) => l.status == 'PENDING').length;
          final suspendedCount = licenses.where((l) => l.status == 'SUSPENDED').length;
          final revokedCount = licenses.where((l) => l.status == 'REVOKED').length;

          // 2. Filter licenses
          final filteredLicenses = licenses.where((l) {
            // Status filter
            if (_statusFilter != 'ALL' && l.status != _statusFilter) {
              return false;
            }

            // Product filter
            if (_selectedProductId != null && l.productId != _selectedProductId) {
              return false;
            }

            // Query filter
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final key = l.licenseKey.toLowerCase();
              final cust = (l.customer?['name'] ?? l.customerId).toString().toLowerCase();
              final comp = (l.customer?['company_name'] ?? '').toString().toLowerCase();
              final prod = (l.product?['name'] ?? l.productId).toString().toLowerCase();
              final plan = (l.plan?['name'] ?? l.planId).toString().toLowerCase();

              final match = key.contains(query) ||
                  cust.contains(query) ||
                  comp.contains(query) ||
                  prod.contains(query) ||
                  plan.contains(query);

              if (!match) return false;
            }

            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              // KPI Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 700;
                      return isNarrow
                          ? Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildMetricCard('Total Lisensi', totalLicenses.toString(), Icons.vpn_key_rounded, Colors.blue),
                                _buildMetricCard('Aktif Terpasang', activeCount.toString(), Icons.check_circle_outline, Colors.green),
                                _buildMetricCard('Menunggu Aktivasi', pendingCount.toString(), Icons.hourglass_top_rounded, Colors.orange),
                                _buildMetricCard('Suspended / Revoked', (suspendedCount + revokedCount).toString(), Icons.block_rounded, Colors.red),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildMetricCard('Total Lisensi', totalLicenses.toString(), Icons.vpn_key_rounded, Colors.blue)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMetricCard('Aktif Terpasang', activeCount.toString(), Icons.check_circle_outline, Colors.green)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMetricCard('Menunggu Aktivasi', pendingCount.toString(), Icons.hourglass_top_rounded, Colors.orange)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMetricCard('Suspended / Revoked', (suspendedCount + revokedCount).toString(), Icons.block_rounded, Colors.red)),
                              ],
                            );
                    },
                  ),
                ),
              ),

              // Filter & Search Toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search field & Product filter
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cari license key, pelanggan, perusahaan, atau produk...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Product Dropdown filter
                              productsAsync.when(
                                data: (products) => Container(
                                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedProductId,
                                    decoration: InputDecoration(
                                      labelText: 'Filter Produk',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Semua Produk'),
                                      ),
                                      ...products.map(
                                        (p) => DropdownMenuItem<String?>(
                                          value: p.id,
                                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) => setState(() => _selectedProductId = val),
                                  ),
                                ),
                                loading: () => const SizedBox(width: 100, height: 40, child: Center(child: CircularProgressIndicator())),
                                error: (_, _) => const SizedBox(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Status Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                _buildFilterChip('Semua ($totalLicenses)', 'ALL', Colors.blueGrey),
                                const SizedBox(width: 8),
                                _buildFilterChip('Aktif ($activeCount)', 'ACTIVE', Colors.green),
                                const SizedBox(width: 8),
                                _buildFilterChip('Pending ($pendingCount)', 'PENDING', Colors.orange),
                                const SizedBox(width: 8),
                                _buildFilterChip('Suspended ($suspendedCount)', 'SUSPENDED', Colors.deepOrange),
                                const SizedBox(width: 8),
                                _buildFilterChip('Revoked ($revokedCount)', 'REVOKED', Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Licenses List Content
              if (filteredLicenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vpn_key_off_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _statusFilter != 'ALL' || _selectedProductId != null
                                ? 'Tidak ada lisensi yang cocok dengan filter.'
                                : 'Belum ada lisensi terdaftar.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          if (_searchQuery.isNotEmpty || _statusFilter != 'ALL' || _selectedProductId != null) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _statusFilter = 'ALL';
                                  _selectedProductId = null;
                                });
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset Filter'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  ),
                                  dataRowMinHeight: 72,
                                  dataRowMaxHeight: 76,
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  columns: const [
                                    DataColumn(label: Text('KODE LISENSI (KEY)')),
                                    DataColumn(label: Text('PELANGGAN')),
                                    DataColumn(label: Text('PRODUK & PAKET')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('PERANGKAT TERIKAT')),
                                    DataColumn(label: Text('AKSI & BAGIKAN')),
                                  ],
                                  rows: filteredLicenses.map((l) {
                                    Plan? matchedPlan;
                                    try {
                                      matchedPlan = plansMap.firstWhere((p) => p.id == l.planId);
                                    } catch (_) {}

                                    final custName = l.customer != null ? l.customer!['name'] : l.customerId;
                                    final compName = l.customer?['company_name'] ?? l.customer?['company'];
                                    final prodName = l.product != null ? l.product!['name'] : l.productId;
                                    final planName = l.plan != null ? l.plan!['name'] : (matchedPlan?.name ?? l.planId);

                                    return DataRow(
                                      cells: [
                                        // 1. License Key Cell with 1-Click Copy
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                                  ),
                                                ),
                                                child: Text(
                                                  l.licenseKey,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.copy_rounded, size: 18),
                                                color: Theme.of(context).colorScheme.primary,
                                                tooltip: '1x Klik: Salin License Key Saja',
                                                onPressed: () => _copyToClipboard(
                                                  l.licenseKey,
                                                  'License Key disalin ke clipboard!',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 2. Customer Cell
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                                child: Text(
                                                  (custName.toString().isNotEmpty ? custName.toString()[0] : 'C').toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    custName.toString(),
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                  if (compName != null && compName.toString().isNotEmpty)
                                                    Text(
                                                      compName.toString(),
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 3. Product & Plan Cell
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                prodName.toString(),
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  planName.toString(),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 4. Status Cell
                                        DataCell(
                                          _buildStatusBadge(l.status),
                                        ),

                                        // 5. Device / Installation Cell
                                        DataCell(
                                          l.status == 'ACTIVE' && l.installation != null
                                              ? Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.desktop_windows_outlined, size: 16, color: Colors.green),
                                                    const SizedBox(width: 6),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          l.installation!['hostname'] ?? 'Device Aktif',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                        Text(
                                                          (l.installation!['platform'] ?? 'PC').toString(),
                                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    l.status == 'ACTIVE' ? 'Perangkat Terikat' : 'Belum Aktivasi',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                  ),
                                                ),
                                        ),

                                        // 6. Actions & 1-Click Share
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // 1-Click Share Button
                                              FilledButton.tonalIcon(
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                onPressed: () => _shareLicense(l, matchedPlan),
                                                icon: const Icon(Icons.share_rounded, size: 15),
                                                label: const Text('Bagikan', style: TextStyle(fontSize: 12)),
                                              ),
                                              const SizedBox(width: 6),

                                              // View Full Details Dialog
                                              IconButton(
                                                icon: const Icon(Icons.info_outline_rounded, size: 19),
                                                tooltip: 'Rincian & Fitur Lengkap',
                                                onPressed: () => _showLicenseDetail(l, matchedPlan),
                                              ),

                                              // Popup Menu for Management Actions
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, size: 20),
                                                tooltip: 'Aksi Lainnya',
                                                onSelected: (action) async {
                                                  final notifier = ref.read(licenseActionProvider.notifier);

                                                  if (action == 'suspend') {
                                                    await notifier.changeStatus(l.id, 'suspend');
                                                  } else if (action == 'resume') {
                                                    await notifier.changeStatus(l.id, 'resume');
                                                  } else if (action == 'revoke') {
                                                    final confirm = await _showConfirmDialog(
                                                      title: 'Cabut Lisensi (Revoke)',
                                                      content: 'Lisensi ini tidak akan dapat digunakan lagi. Yakin ingin mencabut lisensi?',
                                                      confirmText: 'Revoke',
                                                      confirmColor: Colors.red,
                                                    );
                                                    if (confirm == true) {
                                                      await notifier.changeStatus(l.id, 'revoke');
                                                    }
                                                  } else if (action == 'unbind') {
                                                    final confirm = await _showConfirmDialog(
                                                      title: 'Reset Ikatan Perangkat (Unbind)',
                                                      content: 'Lepaskan ikatan perangkat dari lisensi ini? Pelanggan bisa melakukan aktivasi ulang di komputer lain.',
                                                      confirmText: 'Unbind Perangkat',
                                                      confirmColor: Colors.blue,
                                                    );
                                                    if (confirm == true) {
                                                      await notifier.unbindLicense(l.id);
                                                    }
                                                  } else if (action == 'delete') {
                                                    final confirm = await _showConfirmDialog(
                                                      title: 'Hapus Lisensi',
                                                      content: 'Hapus lisensi ${l.licenseKey} secara permanen dari sistem?',
                                                      confirmText: 'Hapus Permanen',
                                                      confirmColor: Colors.red,
                                                    );
                                                    if (confirm == true) {
                                                      await notifier.deleteLicense(l.id);
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  if (l.status != 'SUSPENDED' && l.status != 'REVOKED')
                                                    const PopupMenuItem(
                                                      value: 'suspend',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.pause_circle_outline, size: 18, color: Colors.orange),
                                                          SizedBox(width: 8),
                                                          Text('Tangguhkan (Suspend)'),
                                                        ],
                                                      ),
                                                    ),
                                                  if (l.status == 'SUSPENDED')
                                                    const PopupMenuItem(
                                                      value: 'resume',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.play_circle_outline, size: 18, color: Colors.green),
                                                          SizedBox(width: 8),
                                                          Text('Aktifkan Kembali (Resume)'),
                                                        ],
                                                      ),
                                                    ),
                                                  if (l.status == 'ACTIVE')
                                                    const PopupMenuItem(
                                                      value: 'unbind',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.link_off_rounded, size: 18, color: Colors.blue),
                                                          SizedBox(width: 8),
                                                          Text('Reset Perangkat (Unbind)'),
                                                        ],
                                                      ),
                                                    ),
                                                  if (l.status != 'REVOKED')
                                                    const PopupMenuItem(
                                                      value: 'revoke',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.block_rounded, size: 18, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Cabut Lisensi (Revoke)'),
                                                        ],
                                                      ),
                                                    ),
                                                  const PopupMenuDivider(),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                        SizedBox(width: 8),
                                                        Text('Hapus Lisensi', style: TextStyle(color: Colors.redAccent)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading licenses: $e')),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'PENDING':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        icon = Icons.access_time_rounded;
        break;
      case 'SUSPENDED':
        bg = Colors.deepOrange.shade50;
        fg = Colors.deepOrange.shade900;
        icon = Icons.pause_circle_filled;
        break;
      case 'REVOKED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PREVIEW & BAGIKAN MODAL (WHATSAPP / COPY)
// ==========================================
class _SharePreviewDialog extends StatelessWidget {
  final License license;
  final String shareText;
  final VoidCallback onCopy;

  const _SharePreviewDialog({
    required this.license,
    required this.shareText,
    required this.onCopy,
  });

  void _openWhatsApp(BuildContext context) async {
    final phone = license.customer?['phone']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final encodedText = Uri.encodeComponent(shareText);

    Uri uri;
    if (phone.isNotEmpty) {
      // Normalisasi format internasional (e.g. 0812 -> 62812)
      String cleanPhone = phone;
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '62${cleanPhone.substring(1)}';
      }
      uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    } else {
      uri = Uri.parse('https://api.whatsapp.com/send?text=$encodedText');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = license.customer?['phone'] != null &&
        license.customer!['phone'].toString().trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // High contrast styling for crystal-clear readability in both Light & Dark modes
    final boxBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final boxBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.share_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bagikan Lisensi & Fitur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format keterangan dan fitur lisensi telah disiapkan. Anda dapat langsung menyalinnya atau mengirimkannya via WhatsApp:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: boxBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: boxBorder, width: 1.5),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  shareText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            onCopy();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Salin Teks'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          onPressed: () {
            _openWhatsApp(context);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.chat, size: 16, color: Colors.white),
          label: Text(
            hasPhone ? 'Kirim ke WhatsApp' : 'Kirim via WhatsApp',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// LICENSE DETAIL DIALOG (KOMPREHENSIF)
// ==========================================
class _LicenseDetailDialog extends ConsumerWidget {
  final License license;
  final Plan? plan;
  final VoidCallback onShare;
  final VoidCallback onCopyKey;

  const _LicenseDetailDialog({
    required this.license,
    this.plan,
    required this.onShare,
    required this.onCopyKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custName = license.customer != null ? license.customer!['name'] : license.customerId;
    final compName = license.customer?['company_name'] ?? license.customer?['company'];
    final phone = license.customer?['phone'];
    final email = license.customer?['email'];
    final prodName = license.product != null ? license.product!['name'] : license.productId;
    final planName = license.plan != null ? license.plan!['name'] : (plan?.name ?? license.planId);

    // Get features from plan or license.plan
    List<PlanFeature>? features = plan?.planFeatures;
    if (features == null && license.plan != null && license.plan!['plan_features'] != null) {
      final rawList = license.plan!['plan_features'] as List?;
      features = rawList?.map((e) => PlanFeature.fromJson(e)).toList();
    }

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified_user_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Rincian Lisensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          _buildStatusBadge(license.status),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // License Key Hero Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade900,
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: Colors.white70, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('KODE LISENSI', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          SelectableText(
                            license.licenseKey,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: onCopyKey,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 14),
                          SizedBox(width: 6),
                          Text('Salin Key', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Customer & Product Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context: context,
                      title: 'Data Pelanggan',
                      icon: Icons.person_outline,
                      children: [
                        _buildLabelValue(context, 'Nama', custName.toString()),
                        if (compName != null && compName.toString().isNotEmpty)
                          _buildLabelValue(context, 'Instansi/Toko', compName.toString()),
                        if (phone != null && phone.toString().isNotEmpty)
                          _buildLabelValue(context, 'No. HP', phone.toString()),
                        if (email != null && email.toString().isNotEmpty)
                          _buildLabelValue(context, 'Email', email.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context: context,
                      title: 'Aplikasi & Paket',
                      icon: Icons.apps_outlined,
                      children: [
                        _buildLabelValue(context, 'Produk', prodName.toString()),
                        _buildLabelValue(context, 'Paket Plan', planName.toString()),
                        _buildLabelValue(
                          context,
                          'Dibuat',
                          '${license.createdAt.day.toString().padLeft(2, '0')}-${license.createdAt.month.toString().padLeft(2, '0')}-${license.createdAt.year}',
                        ),
                        if (license.activatedAt != null)
                          _buildLabelValue(
                            context,
                            'Diaktivasi',
                            '${license.activatedAt!.day.toString().padLeft(2, '0')}-${license.activatedAt!.month.toString().padLeft(2, '0')}-${license.activatedAt!.year}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Device / Hardware Installation Card
              _buildInfoCard(
                context: context,
                title: 'Informasi Perangkat Terikat',
                icon: Icons.computer,
                children: [
                  if (license.status == 'ACTIVE' && license.installation != null) ...[
                    _buildLabelValue(context, 'Hostname', license.installation!['hostname'] ?? '-'),
                    _buildLabelValue(context, 'Platform', license.installation!['platform'] ?? '-'),
                    _buildLabelValue(context, 'Fingerprint', license.installation!['machine_fingerprint'] ?? '-'),
                    _buildLabelValue(context, 'App Version', license.installation!['app_version'] ?? '-'),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        license.status == 'ACTIVE'
                            ? 'Lisensi aktif pada perangkat pengguna.'
                            : 'Belum ada perangkat yang terikat. Lisensi siap diaktivasi pelanggan.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Plan Features & Limits Section
              _buildInfoCard(
                context: context,
                title: 'Fitur & Hak Akses Paket ($planName)',
                icon: Icons.star_border_rounded,
                children: [
                  if (features == null || features.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Tidak ada rincian batasan fitur tambahan pada paket ini.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...features.map((f) {
                      final fName = f.feature != null ? f.feature!['name'] : f.featureId;
                      final fDesc = f.feature?['description'];
                      final isBoolean = f.value.toLowerCase() == 'true' || f.value.toLowerCase() == 'false';
                      final isEnabled = f.value.toLowerCase() == 'true';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isBoolean
                                  ? (isEnabled ? Icons.check_circle : Icons.cancel)
                                  : Icons.tune_rounded,
                              size: 16,
                              color: isBoolean ? (isEnabled ? Colors.green : Colors.grey) : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fName.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  if (fDesc != null && fDesc.toString().isNotEmpty)
                                    Text(
                                      fDesc.toString(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isBoolean ? (isEnabled ? 'Aktif' : 'Tidak') : f.value,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onShare();
          },
          icon: const Icon(Icons.share_rounded, size: 16),
          label: const Text('Bagikan Lisensi Ini'),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Divider(
            height: 18,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelValue(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'PENDING':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        break;
      case 'SUSPENDED':
        bg = Colors.deepOrange.shade50;
        fg = Colors.deepOrange.shade900;
        break;
      case 'REVOKED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

// ==========================================
// GENERATE NEW LICENSE DIALOG
// ==========================================
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
      title: const Row(
        children: [
          Icon(Icons.add_moderator, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Generate New License', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customersAsync.when(
              data: (customers) => DropdownButtonFormField<String>(
                initialValue: selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Pelanggan',
                  helperText: 'Pilih customer yang akan memiliki lisensi ini',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name}${c.company != null ? ' (${c.company})' : ''}'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedCustomerId = val),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading customers: $e'),
            ),
            const SizedBox(height: 16),
            productsAsync.when(
              data: (products) => DropdownButtonFormField<String>(
                initialValue: selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Produk Aplikasi',
                  helperText: 'Pilih software yang dilisensikan',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedProductId = val;
                    selectedPlanId = null; // reset plan selection
                  });
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading products: $e'),
            ),
            const SizedBox(height: 16),
            if (selectedProductId != null)
              plansAsync.when(
                data: (plans) {
                  final filteredPlans = plans.where((p) => p.productId == selectedProductId).toList();
                  if (filteredPlans.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Produk ini belum memiliki paket (Plan). Silakan buat paket terlebih dahulu di menu Plans.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: selectedPlanId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Paket Lisensi (Plan)',
                      helperText: 'Pilih jenis paket dan batasan fitur',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: filteredPlans
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.code})'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedPlanId = val),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading plans: $e'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: (selectedCustomerId == null || selectedProductId == null || selectedPlanId == null)
              ? null
              : () async {
                  final success = await ref.read(licenseActionProvider.notifier).createLicense(
                        selectedCustomerId!,
                        selectedProductId!,
                        selectedPlanId!,
                      );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lisensi baru berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
          child: const Text('Buat Lisensi'),
        ),
      ],
    );
  }
}
