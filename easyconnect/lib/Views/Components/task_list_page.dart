import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/task_form_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskController = Get.find<TaskController>();
      final authController = Get.find<AuthController>();
      if (taskController.canAssignTasks) {
        taskController.loadUsers();
        taskController.loadTasks();
      } else {
        // Utilisateurs non-patron : afficher uniquement les tâches qui leur sont assignées
        taskController.setAssignedToFilter(authController.userAuth.value?.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Get.find<TaskController>();
    final authController = Get.find<AuthController>();
    final canAssign = taskController.canAssignTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tâches'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, taskController, canAssign),
          ),
        ],
      ),
      body: Obx(() {
        if (taskController.isLoading.value && taskController.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (taskController.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  canAssign ? 'Aucune tâche' : 'Aucune tâche assignée',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                if (canAssign) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Assignez une tâche à un utilisateur',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => taskController.loadTasks(page: 1),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: taskController.tasks.length,
            itemBuilder: (context, index) {
              final task = taskController.tasks[index];
              return _buildTaskCard(context, task, taskController, canAssign, authController.userAuth.value?.id);
            },
          ),
        );
      }),
      floatingActionButton: canAssign
          ? UniformAddButton(
              onPressed: () => Get.to(() => const TaskFormPage())?.then((_) => taskController.loadTasks()),
              label: 'Assigner une tâche',
              icon: Icons.add_task,
            )
          : null,
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    TaskController controller,
    bool canAssign,
    int? currentUserId,
  ) {
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.toNamed('/tasks/${task.id}')?.then((_) => controller.loadTasks()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.statusLibelle,
                      style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    task.assigneeName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.priorityLibelle,
                      style: TextStyle(fontSize: 11, color: priorityColor),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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

  void _showFilterDialog(BuildContext context, TaskController controller, bool canAssign) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrer par statut', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _filterChip(ctx, 'Tous', null, controller.selectedStatus.value == null, () {
                  controller.setStatusFilter(null);
                  Get.back();
                }),
                _filterChip(ctx, 'En attente', 'pending', controller.selectedStatus.value == 'pending', () {
                  controller.setStatusFilter('pending');
                  Get.back();
                }),
                _filterChip(ctx, 'En cours', 'in_progress', controller.selectedStatus.value == 'in_progress', () {
                  controller.setStatusFilter('in_progress');
                  Get.back();
                }),
                _filterChip(ctx, 'Terminée', 'completed', controller.selectedStatus.value == 'completed', () {
                  controller.setStatusFilter('completed');
                  Get.back();
                }),
              ],
            ),
            if (canAssign && controller.users.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Filtrer par utilisateur', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: controller.selectedAssignedTo.value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ...controller.users.map((u) {
                        final name = '${u.prenom ?? ''} ${u.nom ?? ''}'.trim();
                        final label = name.isEmpty ? (u.email ?? '') : name;
                        return DropdownMenuItem(value: u.id, child: Text(label));
                      }),
                ],
                onChanged: (v) {
                  controller.setAssignedToFilter(v);
                  Get.back();
                },
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                controller.clearFilters();
                Get.back();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String? value, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
