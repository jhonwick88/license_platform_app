import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/installation_provider.dart';

class InstallationsScreen extends ConsumerStatefulWidget {
  const InstallationsScreen({super.key});

  @override
  ConsumerState<InstallationsScreen> createState() => _InstallationsScreenState();
}

class _InstallationsScreenState extends ConsumerState<InstallationsScreen> {
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
    final instAsync = ref.watch(installationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Installations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Installations',
            onPressed: () => ref.invalidate(installationsProvider),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: instAsync.when(
        data: (installations) {
          final filtered = installations.where((i) {
            if (_statusFilter != 'ALL' && i.status != _statusFilter) return false;
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return (i.hostname != null && i.hostname!.toLowerCase().contains(q)) ||
                i.machineFingerprint.toLowerCase().contains(q) ||
                i.licenseId.toLowerCase().contains(q) ||
                i.installationId.toLowerCase().contains(q);
          }).toList();

          final totalCount = installations.length;
          final activeCount = installations.where((i) => i.status == 'ACTIVE').length;

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
                              hintText: 'Cari Hostname, Machine Fingerprint, License ID, atau Install ID...',
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
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'ALL', label: Text('Semua')),
                            ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                            ButtonSegment(value: 'REVOKED', label: Text('Revoked')),
                          ],
                          selected: {_statusFilter},
                          onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMiniStat(context, 'Total Perangkat', '$totalCount', Colors.blue),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Perangkat Aktif', '$activeCount', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Installations List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices_other, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Belum ada data instalasi perangkat.' : 'Perangkat tidak ditemukan.',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Instalasi akan otomatis tercatat saat klien mengaktivasi software di komputer.'
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
                          final inst = filtered[index];
                          final isActive = inst.status == 'ACTIVE';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.laptop_chromebook,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  inst.hostname ?? 'Unknown Host',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (isActive ? Colors.green : Colors.grey).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: (isActive ? Colors.green : Colors.grey).withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    inst.status,
                                                    style: TextStyle(
                                                      color: isActive ? Colors.green : Colors.grey,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Install ID: ${inst.installationId}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.outlineVariant,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 12,
                                    children: [
                                      _buildCopyableField(
                                        context,
                                        'Machine Fingerprint (Hardware ID)',
                                        inst.machineFingerprint,
                                        () => _copy(inst.machineFingerprint, 'Machine Fingerprint'),
                                      ),
                                      _buildCopyableField(
                                        context,
                                        'License ID',
                                        inst.licenseId,
                                        () => _copy(inst.licenseId, 'License ID'),
                                      ),
                                    ],
                                  ),
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
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCopyableField(BuildContext context, String label, String value, VoidCallback onCopy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outlineVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value.length > 32 ? '${value.substring(0, 32)}...' : value,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Salin $label',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
