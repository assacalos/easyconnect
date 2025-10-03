import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class SalaireValidationPage extends StatefulWidget {
  const SalaireValidationPage({Key? key}) : super(key: key);

  @override
  State<SalaireValidationPage> createState() => _SalaireValidationPageState();
}

class _SalaireValidationPageState extends State<SalaireValidationPage> {
  final SalaryService _salaryService = SalaryService();
  List<Salary> _salaireList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadSalaires();
  }

  Future<void> _loadSalaires() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salaires = await _salaryService.getSalaries(
        status: _selectedStatus,
      );
      setState(() {
        _salaireList = salaires;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des salaires: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateSalaire(Salary salaire) async {
    try {
      final success = await _salaryService.approveSalary(salaire.id!);
      if (success) {
        Get.snackbar(
          'Succès',
          'Salaire validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadSalaires();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la validation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectSalaire(Salary salaire, String comment) async {
    try {
      final success = await _salaryService.rejectSalary(
        salaire.id!,
        reason: comment,
      );
      if (success) {
        Get.snackbar(
          'Succès',
          'Salaire rejeté avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadSalaires();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showValidationDialog(Salary salaire) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employé: ${salaire.employeeName}'),
            const SizedBox(height: 8),
            Text('Période: ${salaire.month}'),
            const SizedBox(height: 8),
            Text(
              'Salaire de base: ${salaire.baseSalary.toStringAsFixed(2)} FCFA',
            ),
            const SizedBox(height: 8),
            Text('Total: ${salaire.netSalary.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${salaire.createdBy ?? ''}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce salaire ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateSalaire(salaire);
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

  void _showRejectionDialog(Salary salaire) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le salaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employé: ${salaire.employeeName}'),
            const SizedBox(height: 8),
            Text('Période: ${salaire.month}'),
            const SizedBox(height: 8),
            Text('Total: ${salaire.netSalary.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${salaire.createdBy ?? ''}'),
            const SizedBox(height: 16),
            const Text('Motif du rejet (obligatoire):'),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Saisissez le motif du rejet...',
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
              if (commentController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Veuillez saisir un motif de rejet',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              _rejectSalaire(salaire, commentController.text.trim());
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

  List<Salary> get _filteredSalaires {
    if (_searchQuery.isEmpty) {
      return _salaireList;
    }
    return _salaireList
        .where(
          (salaire) =>
              salaire.employeeName != null &&
                  salaire.employeeName!.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
              salaire.month != null &&
                  salaire.month!.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
              salaire.netSalary.toString().contains(_searchQuery),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Salaires'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSalaires),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par employé, période ou montant...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtres de statut
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('En attente'),
                        selected: _selectedStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                          _loadSalaires();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validés'),
                        selected: _selectedStatus == 'approved',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                          _loadSalaires();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetés'),
                        selected: _selectedStatus == 'rejected',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'rejected';
                          });
                          _loadSalaires();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des salaires
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredSalaires.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun salaire trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredSalaires.length,
                      itemBuilder: (context, index) {
                        final salaire = _filteredSalaires[index];
                        return _buildSalaireCard(salaire);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaireCard(Salary salaire) {
    final statusColor = _getStatusColor(salaire.status ?? '');
    final statusText = _getStatusText(salaire.status ?? '');
    final statusIcon = _getStatusIcon(salaire.status ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salaire.employeeName ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Période: ${salaire.month}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Salaire de base: ${salaire.baseSalary.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${salaire.netSalary.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${salaire.createdBy ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (salaire.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (salaire.notes != null && salaire.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${salaire.notes ?? ''}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (salaire.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(salaire),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(salaire),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Rejeter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (salaire.status == 'rejected' &&
                salaire.rejectionReason != null &&
                salaire.rejectionReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motif du rejet:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salaire.rejectionReason ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
