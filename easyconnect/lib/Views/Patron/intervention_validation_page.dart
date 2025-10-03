import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class InterventionValidationPage extends StatefulWidget {
  const InterventionValidationPage({Key? key}) : super(key: key);

  @override
  State<InterventionValidationPage> createState() =>
      _InterventionValidationPageState();
}

class _InterventionValidationPageState
    extends State<InterventionValidationPage> {
  final InterventionService _interventionService = InterventionService();
  List<Intervention> _interventionList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interventions = await _interventionService.getInterventions(
        status: _selectedStatus,
      );
      setState(() {
        _interventionList = interventions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des interventions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateIntervention(Intervention intervention) async {
    try {
      final success = await _interventionService.approveIntervention(
        intervention.id!,
      );
      if (success) {
        Get.snackbar(
          'Succès',
          'Intervention validée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadInterventions();
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

  Future<void> _rejectIntervention(
    Intervention intervention,
    String comment,
  ) async {
    try {
      final success = await _interventionService.rejectIntervention(
        intervention.id!,
        reason: comment,
      );
      if (success) {
        Get.snackbar(
          'Succès',
          'Intervention rejetée avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadInterventions();
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

  void _showValidationDialog(Intervention intervention) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${intervention.title}'),
            const SizedBox(height: 8),
            Text('Client: ${intervention.clientName}'),
            const SizedBox(height: 8),
            Text('Type: ${intervention.type}'),
            const SizedBox(height: 8),
            Text('Technicien: ${intervention.createdBy}'),
            const SizedBox(height: 8),
            Text(
              'Date prévue: ${intervention.scheduledDate.day}/${intervention.scheduledDate.month}/${intervention.scheduledDate.year}',
            ),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider cette intervention ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateIntervention(intervention);
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

  void _showRejectionDialog(Intervention intervention) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${intervention.title}'),
            const SizedBox(height: 8),
            Text('Client: ${intervention.clientName}'),
            const SizedBox(height: 8),
            Text('Type: ${intervention.type}'),
            const SizedBox(height: 8),
            Text('Technicien: ${intervention.createdBy}'),
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
              _rejectIntervention(intervention, commentController.text.trim());
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

  List<Intervention> get _filteredInterventions {
    if (_searchQuery.isEmpty) {
      return _interventionList;
    }
    return _interventionList
        .where(
          (intervention) =>
              intervention.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              intervention.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              intervention.status.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
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
        title: const Text('Validation des Interventions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInterventions,
          ),
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
                    hintText: 'Rechercher par référence, client ou type...',
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
                          _loadInterventions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validées'),
                        selected: _selectedStatus == 'approved',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                          _loadInterventions();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetées'),
                        selected: _selectedStatus == 'rejected',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'rejected';
                          });
                          _loadInterventions();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des interventions
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInterventions.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucune intervention trouvée',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredInterventions.length,
                      itemBuilder: (context, index) {
                        final intervention = _filteredInterventions[index];
                        return _buildInterventionCard(intervention);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(Intervention intervention) {
    final statusColor = _getStatusColor(intervention.status);
    final statusText = _getStatusText(intervention.status);
    final statusIcon = _getStatusIcon(intervention.status);

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
                        intervention.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client: ${intervention.clientName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${intervention.type}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Technicien: ${intervention.createdBy}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date prévue: ${intervention.scheduledDate.day}/${intervention.scheduledDate.month}/${intervention.scheduledDate.year}',
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
                    if (intervention.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (intervention.description != null &&
                intervention.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${intervention.description}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (intervention.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(intervention),
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
                          onPressed: () => _showRejectionDialog(intervention),
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
            if (intervention.status == 'rejected' &&
                intervention.rejectionReason != null) ...[
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
                      intervention.rejectionReason!,
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
