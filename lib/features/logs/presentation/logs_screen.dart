import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/log_provider.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Logs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No validation logs found.'));
          }
          return Card(
            margin: const EdgeInsets.all(24),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('LOG ID')),
                    DataColumn(label: Text('INSTALL ID')),
                    DataColumn(label: Text('LICENSE ID')),
                    DataColumn(label: Text('RESULT')),
                    DataColumn(label: Text('REASON')),
                  ],
                  rows: logs.map((l) => DataRow(
                    cells: [
                      DataCell(Text(l.id.substring(0, 8))),
                      DataCell(Text(l.installationId)),
                      DataCell(Text(l.licenseId)),
                      DataCell(
                        Chip(
                          label: Text(l.isValid ? 'SUCCESS' : 'FAILED', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: l.isValid ? Colors.green : Colors.red,
                        )
                      ),
                      DataCell(Text(l.failureReason ?? '-')),
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
