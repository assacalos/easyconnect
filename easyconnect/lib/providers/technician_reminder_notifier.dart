import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/technician_reminder_state.dart';
import 'package:easyconnect/services/technician_reminder_service.dart';

final technicianReminderProvider =
    NotifierProvider<TechnicianReminderNotifier, TechnicianReminderState>(
        TechnicianReminderNotifier.new);

class TechnicianReminderNotifier extends Notifier<TechnicianReminderState> {
  final TechnicianReminderService _service = TechnicianReminderService();
  bool _loadingInProgress = false;

  @override
  TechnicianReminderState build() => const TechnicianReminderState();

  Future<void> loadReminders({bool forceRefresh = false}) async {
    if (_loadingInProgress && !forceRefresh) return;
    _loadingInProgress = true;
    final status =
        state.selectedStatus == 'all' ? null : state.selectedStatus;

    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getList(status: status);
      state = state.copyWith(reminders: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    } finally {
      _loadingInProgress = false;
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadReminders(forceRefresh: true);
  }

  Future<bool> createReminder({
    required String title,
    String? notes,
    int? clientId,
    String? companyName,
    required DateTime dueDate,
    required int remindDaysBefore,
  }) async {
    if (title.trim().isEmpty) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _service.create(
        title: title.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        clientId: clientId,
        companyName: companyName?.trim().isEmpty == true ? null : companyName?.trim(),
        dueDate: dueDate,
        remindDaysBefore: remindDaysBefore,
      );
      await loadReminders(forceRefresh: true);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateReminder(
    int id, {
    String? title,
    String? notes,
    int? clientId,
    String? companyName,
    DateTime? dueDate,
    int? remindDaysBefore,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.update(id,
          title: title,
          notes: notes,
          clientId: clientId,
          companyName: companyName,
          dueDate: dueDate,
          remindDaysBefore: remindDaysBefore);
      await loadReminders(forceRefresh: true);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteReminder(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.delete(id);
      await loadReminders(forceRefresh: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markDone(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.markDone(id);
      await loadReminders(forceRefresh: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
