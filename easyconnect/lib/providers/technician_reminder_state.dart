import 'package:easyconnect/Models/technician_reminder_model.dart';

class TechnicianReminderState {
  final List<TechnicianReminder> reminders;
  final bool isLoading;
  final String selectedStatus; // all, pending, done

  const TechnicianReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.selectedStatus = 'all',
  });

  TechnicianReminderState copyWith({
    List<TechnicianReminder>? reminders,
    bool? isLoading,
    String? selectedStatus,
  }) {
    return TechnicianReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  List<TechnicianReminder> get pendingReminders =>
      reminders.where((r) => r.isPending).toList();
}
