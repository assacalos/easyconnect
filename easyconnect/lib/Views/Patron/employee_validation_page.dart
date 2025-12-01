import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:intl/intl.dart';

class EmployeeValidationPage extends StatefulWidget {
  const EmployeeValidationPage({super.key});

  @override
  State<EmployeeValidationPage> createState() => _EmployeeValidationPageState();
}

class _EmployeeValidationPageState extends State<EmployeeValidationPage>
    with SingleTickerProviderStateMixin {
  final EmployeeController controller = Get.find<EmployeeController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadEmployees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadEmployees();
    }
  }

  Future<void> _loadEmployees() async {
    // Charger tous les employés, le filtrage se fera côté client
    controller.selectedStatus.value = 'all';
    await controller.loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Employés'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadEmployees();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      List<Employee> filteredEmployees = controller.employees;

      // Filtrer selon l'onglet actif
      // Statuts réels des employés : active, inactive, terminated, on_leave
      // Pour la validation :
      // - En attente : inactive, null (nouveaux employés non validés)
      // - Validés : active
      // - Rejetés : terminated
      switch (_tabController.index) {
        case 0: // Tous
          filteredEmployees = controller.employees;
          break;
        case 1: // En attente - inactive ou null (nouveaux employés)
          filteredEmployees =
              controller.employees.where((employee) {
                final status = employee.status?.toLowerCase().trim();
                return status == null || status == 'inactive' || status == '';
              }).toList();
          break;
        case 2: // Validés - active
          filteredEmployees =
              controller.employees.where((employee) {
                final status = employee.status?.toLowerCase().trim();
                return status == 'active';
              }).toList();
          break;
        case 3: // Rejetés - terminated
          filteredEmployees =
              controller.employees.where((employee) {
                final status = employee.status?.toLowerCase().trim();
                return status == 'terminated';
              }).toList();
          break;
        default:
          filteredEmployees = controller.employees;
      }

      // Filtrer par recherche
      if (_searchQuery.isNotEmpty) {
        filteredEmployees =
            filteredEmployees
                .where(
                  (employee) =>
                      '${employee.firstName} ${employee.lastName}'
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      employee.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
      }

      if (filteredEmployees.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun employé trouvé',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredEmployees.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final employee = filteredEmployees[index];
          return _buildEmployeeCard(employee);
        },
      );
    });
  }

  Widget _buildEmployeeCard(Employee employee) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(employee.status);
    final statusIcon = _getStatusIcon(employee.status);
    final statusText = employee.statusText;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          '${employee.firstName} ${employee.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    employee.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (employee.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    employee.phone!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Poste', employee.position ?? 'N/A'),
                _buildInfoRow('Département', employee.department ?? 'N/A'),
                if (employee.hireDate != null)
                  _buildInfoRow(
                    'Date d\'embauche',
                    formatDate.format(employee.hireDate!),
                  ),
                if (employee.salary != null)
                  _buildInfoRow(
                    'Salaire',
                    '${employee.salary!.toStringAsFixed(0)} ${employee.currency ?? 'FCFA'}',
                  ),
                const SizedBox(height: 16),
                _buildActionButtons(employee, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Employee employee, Color statusColor) {
    // Vérifier le statut réel de l'employé
    final status = employee.status?.toLowerCase().trim();
    final isPending = status == null || status == '' || status == 'inactive';
    final isValidated = status == 'active';
    final isRejected = status == 'terminated';

    if (isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(employee),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(employee),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (isValidated) {
      // Validé - Afficher seulement info
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Employé validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isRejected) {
      // Rejeté - Afficher motif du rejet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Employé rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Statut: ${employee.statusText}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    final statusLower = status?.toLowerCase().trim();
    switch (statusLower) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'terminated':
        return Colors.red;
      case 'on_leave':
        return Colors.blue;
      case null:
      case '':
        return Colors.grey; // Statut non défini = en attente
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    final statusLower = status?.toLowerCase().trim();
    switch (statusLower) {
      case 'active':
        return Icons.check_circle;
      case 'inactive':
        return Icons.pending;
      case 'terminated':
        return Icons.cancel;
      case 'on_leave':
        return Icons.event_busy;
      case null:
      case '':
        return Icons.help; // Statut non défini = en attente
      default:
        return Icons.help;
    }
  }

  void _showApproveConfirmation(Employee employee) {
    final commentsController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voulez-vous valider l\'employé ${employee.firstName} ${employee.lastName} ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires d\'approbation (optionnel)',
                hintText: 'Ajouter des commentaires...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.approveEmployee(
                employee,
                comments:
                    commentsController.text.trim().isEmpty
                        ? null
                        : commentsController.text.trim(),
              );
              _loadEmployees();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Employee employee) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter l\'employé'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voulez-vous rejeter l\'employé ${employee.firstName} ${employee.lastName} ?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif du rejet (obligatoire)',
                  hintText: 'Expliquez la raison du rejet...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Le motif du rejet est obligatoire',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              controller.rejectEmployee(
                employee,
                reason: reasonController.text.trim(),
              );
              _loadEmployees();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
