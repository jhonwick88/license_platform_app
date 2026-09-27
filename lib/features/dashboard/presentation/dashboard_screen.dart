import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../products/data/product_provider.dart';
import '../../customers/data/customer_provider.dart';
import '../../licenses/data/license_provider.dart';
import '../../installations/data/installation_provider.dart';
import '../../logs/data/log_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final customersAsync = ref.watch(customersProvider);
    final licensesAsync = ref.watch(licensesProvider);
    final installationsAsync = ref.watch(installationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Overview',
            onPressed: () {
              ref.invalidate(productsProvider);
              ref.invalidate(customersProvider);
              ref.invalidate(licensesProvider);
              ref.invalidate(installationsProvider);
              ref.invalidate(logsProvider);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Kontrol & Manajemen Lisensi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ringkasan real-time aktivitas produk, pelanggan, dan perangkat aktif.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. KPI Statistic Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200
                    ? 4
                    : (constraints.maxWidth > 700 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 1200 ? 1.8 : 2.2,
                  children: [
                    // Active Licenses
                    licensesAsync.when(
                      data: (licenses) {
                        final active = licenses.where((l) => l.status == 'ACTIVE').length;
                        final total = licenses.length;
                        return _KpiCard(
                          title: 'Active Licenses',
                          count: '$active',
                          subtitle: 'Total $total lisensi terdaftar',
                          icon: Icons.vpn_key_rounded,
                          color: Colors.blue,
                          onTap: () => context.go('/licenses'),
                        );
                      },
                      loading: () => const _KpiLoadingCard(title: 'Active Licenses', color: Colors.blue),
                      error: (_, __) => const _KpiCard(
                        title: 'Active Licenses',
                        count: '-',
                        subtitle: 'Gagal memuat data',
                        icon: Icons.vpn_key_rounded,
                        color: Colors.blue,
                      ),
                    ),

                    // Customers
                    customersAsync.when(
                      data: (customers) {
                        final active = customers.where((c) => c.status == 'ACTIVE').length;
                        return _KpiCard(
                          title: 'Total Pelanggan',
                          count: '${customers.length}',
                          subtitle: '$active pelanggan aktif',
                          icon: Icons.people_alt_rounded,
                          color: Colors.green,
                          onTap: () => context.go('/customers'),
                        );
                      },
                      loading: () => const _KpiLoadingCard(title: 'Total Pelanggan', color: Colors.green),
                      error: (_, __) => const _KpiCard(
                        title: 'Total Pelanggan',
                        count: '-',
                        subtitle: 'Gagal memuat data',
                        icon: Icons.people_alt_rounded,
                        color: Colors.green,
                      ),
                    ),

                    // Products
                    productsAsync.when(
                      data: (products) {
                        return _KpiCard(
                          title: 'Produk Software',
                          count: '${products.length}',
                          subtitle: 'Aplikasi terintegrasi',
                          icon: Icons.apps_rounded,
                          color: Colors.indigo,
                          onTap: () => context.go('/products'),
                        );
                      },
                      loading: () => const _KpiLoadingCard(title: 'Produk Software', color: Colors.indigo),
                      error: (_, __) => const _KpiCard(
                        title: 'Produk Software',
                        count: '-',
                        subtitle: 'Gagal memuat data',
                        icon: Icons.apps_rounded,
                        color: Colors.indigo,
                      ),
                    ),

                    // Installations
                    installationsAsync.when(
                      data: (inst) {
                        final active = inst.where((i) => i.status == 'ACTIVE').length;
                        return _KpiCard(
                          title: 'Perangkat Terpasang',
                          count: '$active',
                          subtitle: 'Dari ${inst.length} instalasi mesin',
                          icon: Icons.devices_rounded,
                          color: Colors.purple,
                          onTap: () => context.go('/installations'),
                        );
                      },
                      loading: () => const _KpiLoadingCard(title: 'Perangkat Terpasang', color: Colors.purple),
                      error: (_, __) => const _KpiCard(
                        title: 'Perangkat Terpasang',
                        count: '-',
                        subtitle: 'Gagal memuat data',
                        icon: Icons.devices_rounded,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // 2. Quick Action Shortcut Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Aksi Cepat (Quick Shortcuts)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/licenses'),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Buat Lisensi Baru'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.go('/customers'),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Tambah Pelanggan'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.go('/products'),
                          icon: const Icon(Icons.add_box_outlined, size: 18),
                          label: const Text('Tambah Produk'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.go('/plans'),
                          icon: const Icon(Icons.layers_outlined, size: 18),
                          label: const Text('Atur Paket & Fitur'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/logs'),
                          icon: const Icon(Icons.receipt_long_outlined, size: 18),
                          label: const Text('Lihat Validation Logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. Overview Split Grid: Recent Licenses & Products Summary
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildRecentLicensesSection(context, licensesAsync)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildProductDistributionSection(context, productsAsync)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildRecentLicensesSection(context, licensesAsync),
                      const SizedBox(height: 24),
                      _buildProductDistributionSection(context, productsAsync),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLicensesSection(BuildContext context, AsyncValue<List<dynamic>> licensesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Lisensi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/licenses'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Lihat Semua'),
                ),
              ],
            ),
            const Divider(height: 20),
            licensesAsync.when(
              data: (licenses) {
                if (licenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Belum ada lisensi dibuat.', style: TextStyle(color: Colors.grey))),
                  );
                }
                final recent = licenses.reversed.take(5).toList();
                return Column(
                  children: recent.map((lic) {
                    final custName = lic.customer != null ? lic.customer!['name'] : lic.customerId;
                    final prodName = lic.product != null ? lic.product!['name'] : lic.productId;
                    final planName = lic.plan != null ? lic.plan!['name'] : lic.planId;
                    final status = lic.status;
                    final isAct = status == 'ACTIVE';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isAct ? Colors.green : Colors.orange).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isAct ? Icons.check_circle_outline : Icons.pending_outlined,
                              size: 20,
                              color: isAct ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  custName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$prodName • $planName',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAct ? Colors.green : Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDistributionSection(BuildContext context, AsyncValue<List<dynamic>> productsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Katalog Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/products'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Kelola'),
                ),
              ],
            ),
            const Divider(height: 20),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Belum ada produk terdaftar.', style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: products.map((prod) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prod.productCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (prod.description != null && prod.description!.isNotEmpty)
                                  Text(
                                    prod.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiLoadingCard extends StatelessWidget {
  final String title;
  final MaterialColor color;

  const _KpiLoadingCard({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
