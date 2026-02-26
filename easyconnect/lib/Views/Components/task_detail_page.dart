import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<TaskController>().loadTask(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Get.find<TaskController>();
    final authController = Get.find<AuthController>();
    final userId = authController.userAuth.value?.id;
    final role = authController.userAuth.value?.role;
    final canAssign = role == Roles.ADMIN || role == Roles.PATRON;
    final isAssignee = taskController.currentTask.value?.assignedTo == userId;
    // Patron/Admin peuvent aussi valider (changer le statut) des tâches qu'ils ont assignées
    final canChangeStatus = isAssignee || canAssign;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la tâche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (canAssign)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Supprimer la tâche ?'),
                    content: const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: const Text('Annuler')),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await taskController.deleteTask(widget.taskId);
                  if (ok) Get.back();
                }
              },
            ),
        ],
      ),
      body: Obx(() {
        final task = taskController.currentTask.value;
        if (task == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.titre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statusChip(task.statusLibelle, _statusColor(task.status)),
                  const SizedBox(width: 8),
                  _statusChip(task.priorityLibelle, _priorityColor(task.priority)),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(task.description!, style: TextStyle(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 16),
              _infoRow(Icons.person_outline, 'Assigné à', task.assigneeName),
              if (task.assignerName.isNotEmpty) _infoRow(Icons.person, 'Assigné par', task.assignerName),
              if (task.dueDate != null) _infoRow(Icons.calendar_today, 'Date limite', task.dueDate!),
              _infoRow(Icons.access_time, 'Créée le', task.createdAt),
              if (task.completedAt != null) _infoRow(Icons.check_circle, 'Terminée le', task.completedAt!),
              if (canChangeStatus && !task.isCompleted && !task.isCancelled) ...[
                const SizedBox(height: 24),
                const Divider(),
                Text(
                  canAssign && !isAssignee ? 'Valider la tâche' : 'Changer le statut',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (task.status == 'pending')
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await taskController.updateTaskStatus(task.id, 'in_progress');
                          if (ok) taskController.loadTask(task.id);
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('En cours'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    if (task.status == 'pending' || task.status == 'in_progress') ...[
                      if (task.status == 'in_progress') const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await taskController.updateTaskStatus(task.id, 'completed');
                          if (ok) taskController.loadTask(task.id);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Terminer'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
