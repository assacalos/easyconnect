import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/Views/Rh/employee_form.dart';
import 'package:easyconnect/Views/Rh/employee_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/controller_helper.dart';

class EmployeeList extends StatefulWidget {
  const EmployeeList({super.key});

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && mounted) {
        try {
          Get.find<EmployeeController>().loadByStatus(_tabController.index);
        } catch (_) {}
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        try {
          final c = Get.find<EmployeeController>();
          c.loadByStatus(0);
          c.loadEmployeeStats();
          c.loadDepartments();
          c.loadPositions();
        } catch (_) {}
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmployeeController? controller =
        ControllerHelper.findOrNull<EmployeeController>();
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employés')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Configuration incorrecte. Revenez au tableau de bord.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Get.back(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employés'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) => controller.loadByStatus(index),
          tabs: const [
            Tab(text: 'Actifs'),
            Tab(text: 'Inactifs'),
            Tab(text: 'En congé'),
            Tab(text: 'Terminés'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.selectedStatus.value = 'all';
              controller.selectedDepartment.value = 'all';
              controller.selectedPosition.value = 'all';
              controller.searchQuery.value = '';
              controller.loadEmployees(loadAll: true, forceRefresh: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeeList(controller),
              _buildEmployeeList(controller),
              _buildEmployeeList(controller),
              _buildEmployeeList(controller),
            ],
          ),
          if (controller.canManageEmployees)
            Positioned(
              bottom: 80,
              right: 16,
              child: UniformAddButton(
                onPressed: () => Get.to(() => const EmployeeForm()),
                label: 'Nouvel Employé',
                icon: Icons.person_add,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(EmployeeController controller) {
    return Obx(() {
      // Skeleton dès que loading (y compris au changement d'onglet : liste vidée + isLoading = true)
      if (controller.isLoading.value) {
        return const SkeletonSearchResults(itemCount: 6);
      }

      final employeeList = controller.employees;

      if (employeeList.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.loadEmployees(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabController.index == 0
                          ? Icons.person
                          : _tabController.index == 1
                              ? Icons.person_off
                              : _tabController.index == 2
                                  ? Icons.event_available
                                  : Icons.person_remove,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tabController.index == 0
                          ? 'Aucun employé actif'
                          : _tabController.index == 1
                              ? 'Aucun employé inactif'
                              : _tabController.index == 2
                                  ? 'Aucun employé en congé'
                                  : 'Aucun employé terminé',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadEmployees(forceRefresh: true),
        child: PaginatedListView(
          scrollController: controller.scrollController,
          onLoadMore: controller.loadMore,
          hasNextPage: controller.hasNextPage.value,
          isLoadingMore: controller.isLoadingMore.value,
          itemCount: employeeList.length,
          itemBuilder: (context, index) {
            final employee = employeeList[index];
            return _buildEmployeeCard(employee);
          },
        ),
      );
    });
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Get.to(() => EmployeeDetail(employee: employee)),
        borderRadius: BorderRadius.circular(8),
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
