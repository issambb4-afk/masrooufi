import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/features/backup/application/backup_controller.dart';
import 'package:share_plus/share_plus.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);

    ref.listen(backupControllerProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      }
      if (next.successMessage != null && previous?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Export'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Backup / Restore',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Create Backup'),
                    subtitle: const Text('Export all your data as a JSON file'),
                    onTap: () async {
                      final file = await controller.createBackup();
                      if (file != null) {
                        Share.shareXFiles([XFile(file.path)], text: 'Masrooufi Backup');
                      }
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore Backup'),
                    subtitle: const Text('Replace current data with a backup file'),
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Warning'),
                            content: const Text('This will overwrite all existing data. Are you sure you want to proceed?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
                            ],
                          )
                        );
                        if (confirm == true) {
                          await controller.restoreBackup(file);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Export Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart),
                    title: const Text('Export to CSV'),
                    subtitle: const Text('Export your transactions to a spreadsheet'),
                    onTap: () async {
                      final file = await controller.createCsvExport();
                      if (file != null) {
                        Share.shareXFiles([XFile(file.path)], text: 'Masrooufi Export');
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
