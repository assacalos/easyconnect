import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class PaiementValidationPage extends StatefulWidget {
  const PaiementValidationPage({Key? key}) : super(key: key);

  @override
  State<PaiementValidationPage> createState() => _PaiementValidationPageState();
}

class _PaiementValidationPageState extends State<PaiementValidationPage> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentModel> _paiementList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadPaiements();
  }

  Future<void> _loadPaiements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paiements = await _paymentService.getAllPayments(
        status: _selectedStatus,
      );
      setState(() {
        _paiementList = paiements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des paiements: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validatePaiement(PaymentModel paiement) async {
    try {
      final result = await _paymentService.approvePayment(
        paiement.id!,
        comments: 'Validé par le patron',
      );
      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          'Paiement validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadPaiements();
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

  Future<void> _rejectPaiement(PaymentModel paiement, String comment) async {
    try {
      final result = await _paymentService.rejectPayment(
        paiement.id!,
        reason: comment,
      );
      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          'Paiement rejeté avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadPaiements();
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

  void _showValidationDialog(PaymentModel paiement) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${paiement.reference ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Client: ${paiement.clientName}'),
            const SizedBox(height: 8),
            Text('Montant: ${paiement.amount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Méthode: ${paiement.paymentMethod}'),
            const SizedBox(height: 8),
            Text('Soumis par: ${paiement.comptableName}'),
            const SizedBox(height: 8),
            Text(
              'Date: ${paiement.paymentDate.day}/${paiement.paymentDate.month}/${paiement.paymentDate.year}',
            ),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce paiement ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validatePaiement(paiement);
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

  void _showRejectionDialog(PaymentModel paiement) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${paiement.reference ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Client: ${paiement.clientName}'),
            const SizedBox(height: 8),
            Text('Montant: ${paiement.amount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${paiement.comptableName}'),
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
              _rejectPaiement(paiement, commentController.text.trim());
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

  List<PaymentModel> get _filteredPaiements {
    if (_searchQuery.isEmpty) {
      return _paiementList;
    }
    return _paiementList
        .where(
          (paiement) =>
              (paiement.reference ?? '').toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              paiement.clientName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              paiement.amount.toString().contains(_searchQuery),
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
        title: const Text('Validation des Paiements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaiements,
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
                    hintText: 'Rechercher par référence, client ou montant...',
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
                          _loadPaiements();
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
                          _loadPaiements();
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
                          _loadPaiements();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des paiements
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPaiements.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun paiement trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredPaiements.length,
                      itemBuilder: (context, index) {
                        final paiement = _filteredPaiements[index];
                        return _buildPaiementCard(paiement);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementCard(PaymentModel paiement) {
    final statusColor = _getStatusColor(paiement.status);
    final statusText = _getStatusText(paiement.status);
    final statusIcon = _getStatusIcon(paiement.status);

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
                        paiement.reference ?? 'Paiement #${paiement.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client: ${paiement.clientName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant: ${paiement.amount.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Méthode: ${paiement.paymentMethod}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${paiement.comptableName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${paiement.paymentDate.day}/${paiement.paymentDate.month}/${paiement.paymentDate.year}',
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
                    if (paiement.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (paiement.description != null &&
                paiement.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${paiement.description}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (paiement.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(paiement),
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
                          onPressed: () => _showRejectionDialog(paiement),
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
            if (paiement.status == 'rejected' && paiement.notes != null) ...[
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
                      paiement.notes!,
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
