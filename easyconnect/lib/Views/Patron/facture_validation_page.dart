import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class FactureValidationPage extends StatefulWidget {
  const FactureValidationPage({Key? key}) : super(key: key);

  @override
  State<FactureValidationPage> createState() => _FactureValidationPageState();
}

class _FactureValidationPageState extends State<FactureValidationPage> {
  final InvoiceService _invoiceService = InvoiceService();
  List<InvoiceModel> _factureList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, en_attente, valide, rejete

  @override
  void initState() {
    super.initState();
    print('🔄 FactureValidationPage: initState() - Réinitialisation complète');
    _resetState();
    _loadFactures();
  }

  void _resetState() {
    print('🔄 FactureValidationPage: Réinitialisation de l\'état');
    setState(() {
      _factureList = [];
      _isLoading = true;
      _searchQuery = '';
      _selectedStatus = 'all';
    });
  }

  Future<void> _debugAvailableStatuses() async {
    try {
      print('🔍 FactureValidationPage: Débogage des statuts disponibles...');
      final allFactures = await _invoiceService.getAllInvoices();
      print(
        '📊 FactureValidationPage: ${allFactures.length} factures trouvées au total',
      );

      if (allFactures.isNotEmpty) {
        final statuses = allFactures.map((f) => f.status).toSet();
        print(
          '📋 FactureValidationPage: Statuts disponibles: ${statuses.join(', ')}',
        );

        for (final status in statuses) {
          final count = allFactures.where((f) => f.status == status).length;
          print('📊 FactureValidationPage: Statut "$status": $count factures');
        }
      } else {
        print('⚠️ FactureValidationPage: Aucune facture trouvée dans l\'API');
        print('🔍 FactureValidationPage: Vérifications nécessaires:');
        print('  1. L\'endpoint /api/factures-list existe-t-il ?');
        print('  2. La base de données contient-elle des factures ?');
        print(
          '  3. L\'utilisateur a-t-il les permissions pour voir les factures ?',
        );
        print('  4. L\'API retourne-t-elle le bon format JSON ?');
      }
    } catch (e) {
      print('❌ FactureValidationPage: Erreur lors du débogage des statuts: $e');
    }
  }

  Future<void> _loadFactures({bool forceRefresh = false}) async {
    if (forceRefresh) {
      print('🔄 FactureValidationPage: Rechargement forcé demandé');
      // Ne pas réinitialiser le statut sélectionné lors du rechargement forcé
      setState(() {
        _factureList = [];
        _isLoading = true;
        _searchQuery = '';
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print(
        '🔍 FactureValidationPage: Chargement des factures avec statut: $_selectedStatus',
      );

      // Déboguer les statuts disponibles si c'est la première fois
      if (_selectedStatus == 'all' && _factureList.isEmpty) {
        await _debugAvailableStatuses();
      }

      List<InvoiceModel> factures;

      if (_selectedStatus == 'all') {
        // Charger toutes les factures sans filtre
        factures = await _invoiceService.getAllInvoices();
        print(
          '📊 FactureValidationPage: ${factures.length} factures trouvées (tous statuts)',
        );

        // Si aucune facture de l'API, afficher un message informatif
        if (factures.isEmpty) {
          print('⚠️ FactureValidationPage: Aucune facture trouvée dans l\'API');
        }
      } else {
        // Essayer d'abord avec le statut sélectionné
        factures = await _invoiceService.getAllInvoices(
          status: _selectedStatus,
        );

        print(
          '📊 FactureValidationPage: ${factures.length} factures trouvées avec statut $_selectedStatus',
        );

        // Si aucune facture trouvée, essayer des statuts alternatifs
        if (factures.isEmpty) {
          print(
            '⚠️ FactureValidationPage: Aucune facture avec statut $_selectedStatus, essai avec statuts alternatifs',
          );

          // Essayer avec des statuts alternatifs selon le statut sélectionné
          String? alternativeStatus;
          switch (_selectedStatus) {
            case 'en_attente':
              alternativeStatus = 'pending';
              break;
            case 'valide':
              alternativeStatus = 'approved';
              break;
            case 'rejete':
              alternativeStatus = 'rejected';
              break;
          }

          if (alternativeStatus != null) {
            print(
              '🔄 FactureValidationPage: Essai avec statut alternatif: $alternativeStatus',
            );
            factures = await _invoiceService.getAllInvoices(
              status: alternativeStatus,
            );
            print(
              '📊 FactureValidationPage: ${factures.length} factures trouvées avec statut alternatif $alternativeStatus',
            );
          }

          // Si toujours aucune facture, essayer sans filtre
          if (factures.isEmpty) {
            print(
              '⚠️ FactureValidationPage: Aucune facture trouvée, essai sans filtre',
            );
            factures = await _invoiceService.getAllInvoices();
            print(
              '📊 FactureValidationPage: ${factures.length} factures trouvées sans filtre',
            );
          }
        }
      }

      setState(() {
        _factureList = factures;
        _isLoading = false;
      });

      print(
        '✅ FactureValidationPage: État mis à jour avec ${_factureList.length} factures',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ FactureValidationPage: Erreur lors du chargement: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des factures: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateFacture(InvoiceModel facture) async {
    try {
      final result = await _invoiceService.approveInvoice(
        invoiceId: facture.id,
        comments: 'Validé par le patron',
      );
      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          'Facture validée avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadFactures(forceRefresh: true);
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

  Future<void> _rejectFacture(InvoiceModel facture, String comment) async {
    try {
      final result = await _invoiceService.rejectInvoice(
        invoiceId: facture.id,
        reason: comment,
      );
      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          'Facture rejetée avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadFactures(forceRefresh: true);
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

  void _showValidationDialog(InvoiceModel facture) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Numéro: ${facture.invoiceNumber}'),
            const SizedBox(height: 8),
            Text('Client: ${facture.clientName}'),
            const SizedBox(height: 8),
            Text('Montant TTC: ${facture.totalAmount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${facture.commercialName}'),
            const SizedBox(height: 8),
            Text(
              'Date: ${facture.invoiceDate.day}/${facture.invoiceDate.month}/${facture.invoiceDate.year}',
            ),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider cette facture ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateFacture(facture);
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

  void _showRejectionDialog(InvoiceModel facture) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Numéro: ${facture.invoiceNumber}'),
            const SizedBox(height: 8),
            Text('Client: ${facture.clientName}'),
            const SizedBox(height: 8),
            Text('Montant TTC: ${facture.totalAmount.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${facture.commercialName}'),
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
              _rejectFacture(facture, commentController.text.trim());
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

  List<InvoiceModel> get _filteredFactures {
    if (_searchQuery.isEmpty) {
      return _factureList;
    }
    return _factureList
        .where(
          (facture) =>
              facture.invoiceNumber.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              facture.clientName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              facture.totalAmount.toString().contains(_searchQuery),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'valide':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.access_time;
      case 'valide':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Factures'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFactures(forceRefresh: true),
            tooltip: 'Actualiser la liste',
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
                    hintText: 'Rechercher par numéro, client ou montant...',
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
                        label: const Text('Tous'),
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'all';
                          });
                          _loadFactures(forceRefresh: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('En attente'),
                        selected: _selectedStatus == 'en_attente',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'en_attente';
                          });
                          _loadFactures(forceRefresh: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validées'),
                        selected: _selectedStatus == 'valide',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'valide';
                          });
                          _loadFactures(forceRefresh: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetées'),
                        selected: _selectedStatus == 'rejete',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'rejete';
                          });
                          _loadFactures(forceRefresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des factures
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFactures.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune facture trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vérifiez que l\'API retourne des données',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _loadFactures(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredFactures.length,
                      itemBuilder: (context, index) {
                        final facture = _filteredFactures[index];
                        return _buildFactureCard(facture);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactureCard(InvoiceModel facture) {
    final statusColor = _getStatusColor(facture.status);
    final statusText = _getStatusText(facture.status);
    final statusIcon = _getStatusIcon(facture.status);

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
                        facture.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client: ${facture.clientName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant TTC: ${facture.totalAmount.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${facture.commercialName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${facture.invoiceDate.day}/${facture.invoiceDate.month}/${facture.invoiceDate.year}',
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
                    if (facture.status == 'en_attente') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (facture.notes != null && facture.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${facture.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (facture.status ==
                'en_attente') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(facture),
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
                          onPressed: () => _showRejectionDialog(facture),
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
            if (facture.status == 'rejete' && facture.notes != null) ...[
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
                      facture.notes!,
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
