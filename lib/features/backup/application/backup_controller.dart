import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/features/backup/domain/repositories/backup_repository.dart';

class BackupState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  BackupState({this.isLoading = false, this.error, this.successMessage});

  BackupState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class BackupController extends StateNotifier<BackupState> {
  BackupController() : super(BackupState());

  late final BackupRepository _backupRepository = sl<BackupRepository>();

  void injectDependencies(BackupRepository repo) {
    // for testing
  }

  Future<File?> createBackup() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final file = await _backupRepository.createBackup();
      state = state.copyWith(isLoading: false, successMessage: 'Backup created successfully');
      return file;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> restoreBackup(File file) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _backupRepository.restoreBackup(file);
      state = state.copyWith(isLoading: false, successMessage: 'Backup restored successfully');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to restore backup: $e');
      return false;
    }
  }

  Future<File?> createCsvExport() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final file = await _backupRepository.createCsvExport();
      state = state.copyWith(isLoading: false, successMessage: 'Export created successfully');
      return file;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final backupControllerProvider = StateNotifierProvider<BackupController, BackupState>((ref) {
  return BackupController();
});
