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
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label disalin! ($text)'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instAsync = ref.watch(installationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Installations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
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
          final revokedCount = installations.where((i) => i.status != 'ACTIVE').length;

          return CustomScrollView(
            slivers: [
              // Search & Filter Header (Compact Bar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari Hostname, Install ID, License ID, atau Fingerprint...',
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
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(value: 'ALL', label: Text('Semua ($totalCount)', style: const TextStyle(fontSize: 12))),
                              ButtonSegment(value: 'ACTIVE', label: Text('Active ($activeCount)', style: const TextStyle(fontSize: 12))),
                              ButtonSegment(value: 'REVOKED', label: Text('Revoked ($revokedCount)', style: const TextStyle(fontSize: 12))),
                            ],
                            selected: {_statusFilter},
                            onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Installations List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'Belum ada data instalasi perangkat.' : 'Perangkat tidak ditemukan.',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Instalasi akan otomatis tercatat saat klien mengaktivasi software di komputer.'
                              : 'Coba ubah kata kunci pencarian atau filter status.',
                          style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final inst = filtered[index];
                        final isActive = inst.status == 'ACTIVE';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Device Icon + Status Badge
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.laptop_chromebook,
                                    color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Main Info: Hostname & Platform
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              inst.hostname?.isNotEmpty == true ? inst.hostname! : 'Unknown Device',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              inst.status,
                                              style: TextStyle(
                                                color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Platform: ${inst.platform ?? '-'} • App: v${inst.appVersion ?? '1.0.0'}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Install ID Chip with 1-Click Copy
                                Expanded(
                                  flex: 2,
                                  child: _buildCompactIdBadge(
                                    context: context,
                                    label: 'INSTALL ID',
                                    value: inst.installationId,
                                    icon: Icons.qr_code_2_rounded,
                                    onCopy: () => _copy(inst.installationId, 'Install ID'),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // License ID Chip with 1-Click Copy
                                Expanded(
                                  flex: 2,
                                  child: _buildCompactIdBadge(
                                    context: context,
                                    label: 'LICENSE ID',
                                    value: inst.licenseId,
                                    icon: Icons.verified_user_outlined,
                                    onCopy: () => _copy(inst.licenseId, 'License ID'),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Hardware Fingerprint Chip with 1-Click Copy
                                Expanded(
                                  flex: 2,
                                  child: _buildCompactIdBadge(
                                    context: context,
                                    label: 'FINGERPRINT',
                                    value: inst.machineFingerprint,
                                    icon: Icons.fingerprint_rounded,
                                    onCopy: () => _copy(inst.machineFingerprint, 'Machine Fingerprint'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
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

  Widget _buildCompactIdBadge({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayVal = value.length > 20 ? '${value.substring(0, 18)}...' : value;

    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blueAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    displayVal,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ],
        ),
      ),
    );
  }
}
