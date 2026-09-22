import 'dart:io';

abstract class BackupRepository {
  Future<File> createBackup();
  Future<void> restoreBackup(File file);
  Future<File> createCsvExport();
}
