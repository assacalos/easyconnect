import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/technician_reminder_notifier.dart';
import 'package:easyconnect/providers/technician_reminder_state.dart';
import 'package:easyconnect/Models/technician_reminder_model.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class TechnicianReminderListPage extends ConsumerStatefulWidget {
  const TechnicianReminderListPage({super.key});

  @override
  ConsumerState<TechnicianReminderListPage> createState() =>
      _TechnicianReminderListPageState();
}

class _TechnicianReminderListPageState extends ConsumerState<TechnicianReminderListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(technicianReminderProvider.notifier).loadReminders(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianReminderProvider);
    final notifier = ref.read(technicianReminderProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(
            fallbackRoute: '/technicien', iconColor: Colors.white),
        title: const Text('Mes rappels'),
        backgroundColor: const Color(0xFFC2410C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadReminders(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip(context, notifier, state.selectedStatus, 'all', 'Tous'),
                _chip(context, notifier, state.selectedStatus, 'pending', 'À faire'),
                _chip(context, notifier, state.selectedStatus, 'done', 'Fait'),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, state, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/mes-rappels/new');
          if (context.mounted) {
            ref.read(technicianReminderProvider.notifier).loadReminders(forceRefresh: true);
          }
        },
        icon: const Icon(Icons.add_alarm),
        label: const Text('Nouveau rappel'),
        backgroundColor: const Color(0xFFC2410C),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    TechnicianReminderNotifier notifier,
    String selectedValue,
    String value,
    String label,
  ) {
    final selected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => notifier.filterByStatus(value),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TechnicianReminderState state,
    TechnicianReminderNotifier notifier,
  ) {
    if (state.isLoading && state.reminders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.reminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun rappel',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez des rappels (piles à recharger, radio en maintenance…)\npour être notifié 1, 2 ou 3 jours avant la date limite.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.reminders.length,
      itemBuilder: (context, index) {
        final reminder = state.reminders[index];
        return _ReminderCard(
          reminder: reminder,
          onMarkDone: () => _confirmMarkDone(context, reminder, notifier),
          onDelete: () => _confirmDelete(context, reminder, notifier),
        );
      },
    );
  }

  void _confirmMarkDone(
    BuildContext context,
    TechnicianReminder reminder,
    TechnicianReminderNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme fait'),
        content: Text(
          'Marquer « ${reminder.title} » comme fait ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await notifier.markDone(reminder.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rappel marqué comme fait.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _confirmDelete(
    BuildContext context,
    TechnicianReminder reminder,
    TechnicianReminderNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rappel'),
        content: Text(
          'Supprimer « ${reminder.title} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await notifier.deleteReminder(reminder.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rappel supprimé.')),
        );
      }
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final TechnicianReminder reminder;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onMarkDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final company = reminder.companyDisplay ?? reminder.companyName ?? '—';
    final isOverdue = reminder.isPending &&
        reminder.dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Entreprise : $company'),
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  reminder.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    reminder.remindDaysLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor: reminder.isPending
                      ? (isOverdue ? Colors.red.shade100 : Colors.orange.shade100)
                      : Colors.green.shade100,
                  label: Text(
                    reminder.isPending
                        ? (isOverdue ? 'En retard' : 'À faire')
                        : 'Fait',
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Date limite : ${dateFormat.format(reminder.dueDate)}',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue && reminder.isPending ? Colors.red : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: reminder.isPending
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'done') onMarkDone();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'done',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marquer comme fait'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
