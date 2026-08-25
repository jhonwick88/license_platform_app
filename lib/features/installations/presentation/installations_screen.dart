import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/installation_provider.dart';

class InstallationsScreen extends ConsumerWidget {
  const InstallationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instAsync = ref.watch(installationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Installations', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: instAsync.when(
        data: (installations) {
          if (installations.isEmpty) {
            return const Center(child: Text('No installations found.'));
          }
          return Card(
            margin: const EdgeInsets.all(24),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                  columns: const [
                    DataColumn(label: Text('INSTALL ID')),
                    DataColumn(label: Text('LICENSE ID')),
                    DataColumn(label: Text('HOSTNAME')),
                    DataColumn(label: Text('FINGERPRINT')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: installations.map((i) => DataRow(
                    cells: [
                      DataCell(Text(i.installationId)),
                      DataCell(Text(i.licenseId)),
                      DataCell(Text(i.hostname ?? '-')),
                      DataCell(Text(i.machineFingerprint)),
                      DataCell(
                        Chip(
                          label: Text(i.status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: i.status == 'ACTIVE' ? Colors.green : Colors.grey,
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
