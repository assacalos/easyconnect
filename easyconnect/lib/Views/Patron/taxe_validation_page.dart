import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class TaxeValidationPage extends StatefulWidget {
  const TaxeValidationPage({Key? key}) : super(key: key);

  @override
  State<TaxeValidationPage> createState() => _TaxeValidationPageState();
}

class _TaxeValidationPageState extends State<TaxeValidationPage> {
  final TaxService _taxService = TaxService();
  List<Tax> _taxeList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadTaxes();
  }

  Future<void> _loadTaxes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 TaxeValidationPage._loadTaxes - Début');
      print('📊 Paramètres: status=$_selectedStatus');

      final taxes = await _taxService.getTaxes(status: _selectedStatus);

      print(
        '📊 TaxeValidationPage._loadTaxes - ${taxes.length} taxes chargées',
      );
      for (final taxe in taxes) {
        print('📋 Taxe: ${taxe.id} - Status: ${taxe.status}');
      }

      setState(() {
        _taxeList = taxes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ TaxeValidationPage._loadTaxes - Erreur: $e');
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des taxes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateTaxe(Tax taxe) async {
    try {
      final success = await _taxService.approveTax(taxe.id!);
      if (success) {
        Get.snackbar(
          'Succès',
          'Taxe validée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadTaxes();
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

  Future<void> _rejectTaxe(Tax taxe, String comment) async {
    try {
      final success = await _taxService.rejectTax(
        taxe.id!,
        reason: comment,
        notes: null,
      );
      if (success) {
        Get.snackbar(
          'Succès',
          'Taxe rejetée avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadTaxes();
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

  void _showValidationDialog(Tax taxe) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider la taxe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${taxe.name}'),
            const SizedBox(height: 8),
            Text(
              'Période: ${taxe.dueDate.day}/${taxe.dueDate.month}/${taxe.dueDate.year}',
            ),
            const SizedBox(height: 8),
            Text('Montant: ${taxe.amount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text(
              'Date d\'échéance: ${taxe.dueDate.day}/${taxe.dueDate.month}/${taxe.dueDate.year}',
            ),
            const SizedBox(height: 8),
            Text('Soumis par: ${taxe.user.name}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider cette taxe ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateTaxe(taxe);
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

  void _showRejectionDialog(Tax taxe) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la taxe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${taxe.name}'),
            const SizedBox(height: 8),
            Text(
              'Période: ${taxe.dueDate.day}/${taxe.dueDate.month}/${taxe.dueDate.year}',
            ),
            const SizedBox(height: 8),
            Text('Montant: ${taxe.amount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${taxe.user.name}'),
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
              _rejectTaxe(taxe, commentController.text.trim());
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

  List<Tax> get _filteredTaxes {
    if (_searchQuery.isEmpty) {
      return _taxeList;
    }
    return _taxeList
        .where(
          (taxe) =>
              taxe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              taxe.dueDate.day.toString().contains(
                _searchQuery.toLowerCase(),
              ) ||
              taxe.dueDate.month.toString().contains(
                _searchQuery.toLowerCase(),
              ) ||
              taxe.dueDate.year.toString().contains(
                _searchQuery.toLowerCase(),
              ) ||
              taxe.amount.toString().contains(_searchQuery),
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
        title: const Text('Validation des Taxes et Impôts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTaxes),
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
                    hintText: 'Rechercher par type, période ou montant...',
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
                          _loadTaxes();
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
                          _loadTaxes();
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
                          _loadTaxes();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des taxes
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTaxes.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucune taxe trouvée',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredTaxes.length,
                      itemBuilder: (context, index) {
                        final taxe = _filteredTaxes[index];
                        return _buildTaxeCard(taxe);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxeCard(Tax taxe) {
    final statusColor = _getStatusColor(taxe.status);
    final statusText = _getStatusText(taxe.status);
    final statusIcon = _getStatusIcon(taxe.status);

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
                        taxe.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Période: ${taxe.dueDate.day}/${taxe.dueDate.month}/${taxe.dueDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant: ${taxe.amount.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date d\'échéance: ${taxe.dueDate.day}/${taxe.dueDate.month}/${taxe.dueDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${taxe.user.name}',
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
                    if (taxe.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (taxe.description != null && taxe.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${taxe.description}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (taxe.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(taxe),
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
                          onPressed: () => _showRejectionDialog(taxe),
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
            if (taxe.status == 'rejected' && taxe.rejectionReason != null) ...[
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
                      taxe.rejectionReason!,
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
