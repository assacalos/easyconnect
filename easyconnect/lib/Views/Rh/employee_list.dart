import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/Views/Rh/employee_form.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class EmployeeList extends StatelessWidget {
  const EmployeeList({super.key});

  @override
  Widget build(BuildContext context) {
    final EmployeeController controller = Get.put(EmployeeController());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employés'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Actifs'),
              Tab(text: 'Inactifs'),
              Tab(text: 'En congé'),
              Tab(text: 'Terminés'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadEmployees(),
            ),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildEmployeeListByStatus('active', controller),
                _buildEmployeeListByStatus('inactive', controller),
                _buildEmployeeListByStatus('on_leave', controller),
                _buildEmployeeListByStatus('terminated', controller),
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            if (controller.canManageEmployees)
              UniformAddButton(
                onPressed: () => Get.to(() => const EmployeeForm()),
                label: 'Nouvel Employé',
                icon: Icons.person_add,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeListByStatus(
    String status,
    EmployeeController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final employeeList =
          controller.employees.where((e) => e.status == status).toList();

      if (employeeList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'active'
                    ? Icons.person
                    : status == 'inactive'
                    ? Icons.person_off
                    : status == 'on_leave'
                    ? Icons.event_available
                    : Icons.person_remove,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 'active'
                    ? 'Aucun employé actif'
                    : status == 'inactive'
                    ? 'Aucun employé inactif'
                    : status == 'on_leave'
                    ? 'Aucun employé en congé'
                    : 'Aucun employé terminé',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employeeList.length,
        itemBuilder: (context, index) {
          final employee = employeeList[index];
          return _buildEmployeeCard(employee);
        },
      );
    });
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${employee.firstName} ${employee.lastName}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(employee.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(employee.status),
                        size: 16,
                        color: _getStatusColor(employee.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(employee.status),
                        style: TextStyle(
                          color: _getStatusColor(employee.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Informations employé
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    employee.email,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.work, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(employee.position ?? 'Non défini'),
              ],
            ),
            const SizedBox(height: 4),

            if (employee.department != null)
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(employee.department!),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'on_leave':
        return 'En congé';
      case 'terminated':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'on_leave':
        return Colors.blue;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'active':
        return Icons.person;
      case 'inactive':
        return Icons.person_off;
      case 'on_leave':
        return Icons.event_available;
      case 'terminated':
        return Icons.person_remove;
      default:
        return Icons.help;
    }
  }
}
