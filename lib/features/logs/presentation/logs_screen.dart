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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isValid ? Colors.green : Colors.red).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      color: isValid ? Colors.green : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: (isValid ? Colors.green : Colors.red).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: (isValid ? Colors.green : Colors.red).withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isValid ? 'VALIDATED (SUCCESS)' : 'VALIDATION FAILED',
                                                    style: TextStyle(
                                                      color: isValid ? Colors.green : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Log ID: ${log.id.length > 8 ? log.id.substring(0, 8) : log.id}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.outlineVariant,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (!isValid && log.failureReason != null && log.failureReason!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.red.withOpacity(0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info_outline, color: Colors.red, size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Alasan: ${log.failureReason}',
                                                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            _buildInlineId(context, 'License ID', log.licenseId, () => _copy(log.licenseId, 'License ID')),
                                            _buildInlineId(context, 'Install ID', log.installationId, () => _copy(log.installationId, 'Install ID')),
                                          ],
                                        ),
                                      ],
                                    ),
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

  Widget _buildInlineId(BuildContext context, String label, String value, VoidCallback onCopy) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outlineVariant)),
        Text(
          value.length > 20 ? '${value.substring(0, 20)}...' : value,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Icon(Icons.copy, size: 14, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
