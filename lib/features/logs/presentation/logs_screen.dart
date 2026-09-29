import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/log_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, SUCCESS, FAILED

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
    final logsAsync = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Logs & Audit', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Logs',
            onPressed: () => ref.invalidate(logsProvider),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          final filtered = logs.where((l) {
            if (_statusFilter == 'SUCCESS' && !l.isValid) return false;
            if (_statusFilter == 'FAILED' && l.isValid) return false;
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return l.id.toLowerCase().contains(q) ||
                l.installationId.toLowerCase().contains(q) ||
                l.licenseId.toLowerCase().contains(q) ||
                (l.failureReason != null && l.failureReason!.toLowerCase().contains(q));
          }).toList();

          final total = logs.length;
          final successCount = logs.where((l) => l.isValid).length;
          final failedCount = total - successCount;
          final successRate = total > 0 ? ((successCount / total) * 100).toStringAsFixed(1) : '100';

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
                              hintText: 'Cari Log ID, License ID, Install ID, atau Alasan Gagal...',
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
                            ButtonSegment(value: 'ALL', label: Text('Semua Log')),
                            ButtonSegment(value: 'SUCCESS', label: Text('Valid (Success)')),
                            ButtonSegment(value: 'FAILED', label: Text('Gagal (Failed)')),
                          ],
                          selected: {_statusFilter},
                          onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary KPIs
                    Row(
                      children: [
                        _buildMiniStat(context, 'Total Validasi', '$total', Colors.blue),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Success', '$successCount', Colors.green),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Failed', '$failedCount', Colors.red),
                        const SizedBox(width: 12),
                        _buildMiniStat(context, 'Success Rate', '$successRate%', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Logs List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_outlined, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Belum ada log validasi lisensi.' : 'Log tidak ditemukan.',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Setiap request validasi dari aplikasi klien akan tercatat di sini.'
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
                          final log = filtered[index];
                          final isValid = log.isValid;
                          final dateStr = log.createdAt != null
                              ? '${log.createdAt!.day.toString().padLeft(2, '0')}/${log.createdAt!.month.toString().padLeft(2, '0')}/${log.createdAt!.year} ${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}:${log.createdAt!.second.toString().padLeft(2, '0')}'
                              : '-';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isValid
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Status Indicator Icon
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (isValid ? Colors.green : Colors.red).withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      color: isValid ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Timestamp & Status Badge
                                  SizedBox(
                                    width: 175,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: (isValid ? Colors.green : Colors.red).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: (isValid ? Colors.green : Colors.red).withOpacity(0.4),
                                                ),
                                              ),
                                              child: Text(
                                                isValid ? 'VALIDATED' : 'FAILED',
                                                style: TextStyle(
                                                  color: isValid ? Colors.green.shade800 : Colors.red.shade800,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10.5,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Center: Failure Reason or Success Info + IP Address
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isValid && log.failureReason != null && log.failureReason!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.red.withOpacity(0.35)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.error, color: Colors.red, size: 15),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    log.failureReason!,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Text(
                                            'Validasi Lisensi Klien Berhasil',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        if (log.ipAddress != null && log.ipAddress!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.wifi, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Text(
                                                'IP: ${log.ipAddress}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // ID Badges with 1-Click Copy
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      _buildCompactIdBadge(
                                        context: context,
                                        label: 'License',
                                        value: log.licenseId,
                                        color: Colors.purple,
                                        onCopy: () => _copy(log.licenseId, 'License ID'),
                                      ),
                                      _buildCompactIdBadge(
                                        context: context,
                                        label: 'Install',
                                        value: log.installationId,
                                        color: Colors.blue,
                                        onCopy: () => _copy(log.installationId, 'Install ID'),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
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

  Widget _buildCompactIdBadge({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onCopy,
  }) {
    final display = value.length > 12 ? '${value.substring(0, 10)}...' : value;
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 11.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}
