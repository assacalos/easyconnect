import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/utils/roles.dart';

class DevisValidationPage extends StatefulWidget {
  const DevisValidationPage({Key? key}) : super(key: key);

  @override
  State<DevisValidationPage> createState() => _DevisValidationPageState();
}

class _DevisValidationPageState extends State<DevisValidationPage> {
  final DevisController _devisController = Get.find<DevisController>();
  List<Devis> _devisList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedStatus = 1; // 1: En attente, 2: Validé, 3: Rejeté

  @override
  void initState() {
    super.initState();
    _loadDevis();
  }

  Future<void> _loadDevis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 DevisValidationPage._loadDevis - Début');
      print('📊 Paramètres: status=$_selectedStatus');

      await _devisController.loadDevis(status: _selectedStatus);

      print(
        '📊 DevisValidationPage._loadDevis - ${_devisController.devis.length} devis chargés',
      );
      for (final devis in _devisController.devis) {
        print('📋 Devis: ${devis.id} - Status: ${devis.status}');
      }

      setState(() {
        _devisList = _devisController.devis;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DevisValidationPage._loadDevis - Erreur: $e');
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des devis: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateDevis(Devis devis) async {
    try {
      await _devisController.acceptDevis(devis.id!);
      Get.snackbar(
        'Succès',
        'Devis validé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _loadDevis();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la validation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectDevis(Devis devis, String comment) async {
    try {
      await _devisController.rejectDevis(devis.id!, comment);
      Get.snackbar(
        'Succès',
        'Devis rejeté avec succès',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      _loadDevis();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showValidationDialog(Devis devis) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${devis.reference}'),
            const SizedBox(height: 8),
            Text('Montant TTC: ${devis.totalTTC.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text(
              'Soumis par: ${devis.commercialId}',
            ), // À remplacer par le nom de l'utilisateur
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce devis ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateDevis(devis);
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

  void _showRejectionDialog(Devis devis) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Référence: ${devis.reference}'),
            const SizedBox(height: 8),
            Text('Montant TTC: ${devis.totalTTC.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text(
              'Soumis par: ${devis.commercialId}',
            ), // À remplacer par le nom de l'utilisateur
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
              _rejectDevis(devis, commentController.text.trim());
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

  List<Devis> get _filteredDevis {
    if (_searchQuery.isEmpty) {
      return _devisList;
    }
    return _devisList
        .where(
          (devis) =>
              devis.reference.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              devis.totalTTC.toString().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Get.put(DevisController());
    final controller = Get.find<DevisController>();
    controller.loadDevis(status: _selectedStatus);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Devis'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDevis),
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
                    hintText: 'Rechercher par référence ou montant...',
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
                        selected: _selectedStatus == 1,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 1;
                          });
                          _loadDevis();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validés'),
                        selected: _selectedStatus == 2,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 2;
                          });
                          _loadDevis();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetés'),
                        selected: _selectedStatus == 3,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 3;
                          });
                          _loadDevis();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des devis
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDevis.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun devis trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredDevis.length,
                      itemBuilder: (context, index) {
                        final devis = _filteredDevis[index];
                        return _buildDevisCard(devis);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevisCard(Devis devis) {
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
                        devis.reference,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant TTC: ${devis.totalTTC.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${devis.commercialId}', // À remplacer par le nom de l'utilisateur
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${devis.dateCreation.day}/${devis.dateCreation.month}/${devis.dateCreation.year}',
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
                        color: devis.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: devis.statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            devis.statusIcon,
                            size: 16,
                            color: devis.statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            devis.statusText,
                            style: TextStyle(
                              color: devis.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (devis.status == 1) // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (devis.notes != null && devis.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${devis.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (devis.status == 1) // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(devis),
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
                          onPressed: () => _showRejectionDialog(devis),
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
            if (devis.status == 3 && devis.commentaire != null) ...[
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
                      devis.commentaire!,
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
