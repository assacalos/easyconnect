import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';

class BonCommandeValidationPage extends StatefulWidget {
  const BonCommandeValidationPage({super.key});

  @override
  State<BonCommandeValidationPage> createState() =>
      _BonCommandeValidationPageState();
}

class _BonCommandeValidationPageState extends State<BonCommandeValidationPage>
    with SingleTickerProviderStateMixin {
  late final BonCommandeController controller;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vérifier et initialiser le contrôleur
    if (!Get.isRegistered<BonCommandeController>()) {
      Get.put(BonCommandeController(), permanent: true);
    }
    controller = Get.find<BonCommandeController>();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadBonCommandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadBonCommandes();
    }
  }

  Future<void> _loadBonCommandes() async {
    int? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 1;
        break;
      case 2: // Validés
        status = 2;
        break;
      case 3: // Rejetés
        status = 3;
        break;
    }

    await controller.loadBonCommandes(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Bons de Commande'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBonCommandes();
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
                hintText: 'Rechercher par ID...',
                prefixIcon: const Icon(Icons.search),
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
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBonCommandeList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonCommandeList() {
    // Filtrer les bons de commande selon la recherche
    final filteredBonCommandes =
        _searchQuery.isEmpty
            ? controller.bonCommandes
            : controller.bonCommandes
                .where(
                  (bon) =>
                      bon.id.toString().contains(_searchQuery) ||
                      bon.clientId.toString().contains(_searchQuery),
                )
                .toList();

    if (filteredBonCommandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun bon de commande trouvé'
                  : 'Aucun bon de commande correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredBonCommandes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bonCommande = filteredBonCommandes[index];
        return _buildBonCommandeCard(context, bonCommande);
      },
    );
  }

  Widget _buildBonCommandeCard(BuildContext context, BonCommande bonCommande) {
    final statusColor = _getStatusColor(bonCommande.status);
    final statusIcon = _getStatusIcon(bonCommande.status);
    final statusText = _getStatusText(bonCommande.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Bon de commande #${bonCommande.id ?? 'N/A'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client ID: ${bonCommande.clientId}'),
            Text('Fichiers: ${bonCommande.fichiers.length}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${bonCommande.id ?? 'N/A'}'),
                      Text('Client ID: ${bonCommande.clientId}'),
                      Text('Commercial ID: ${bonCommande.commercialId}'),
                      Text('Fichiers: ${bonCommande.fichiers.length}'),
                      if (bonCommande.fichiers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Liste des fichiers:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...bonCommande.fichiers.map(
                          (fichier) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(fichier)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(bonCommande, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BonCommande bonCommande, Color statusColor) {
    switch (bonCommande.status) {
      case 1: // En attente - Afficher boutons Valider/Rejeter
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(bonCommande),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(bonCommande),
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
      case 2: // Validé - Afficher seulement info
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
                'Bon de commande validé',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 3: // Rejeté - Afficher motif du rejet
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
                'Bon de commande rejeté',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default: // Autres statuts
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
                'Statut: ${bonCommande.status}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1: // En attente
        return Colors.orange;
      case 2: // Validé
        return Colors.green;
      case 3: // Rejeté
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1: // En attente
        return Icons.pending;
      case 2: // Validé
        return Icons.check_circle;
      case 3: // Rejeté
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: // En attente
        return 'En attente';
      case 2: // Validé
        return 'Validé';
      case 3: // Rejeté
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(BonCommande bonCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce bon de commande ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveBonCommande(bonCommande.id!);
        _loadBonCommandes();
      },
    );
  }

  void _showRejectDialog(BonCommande bonCommande) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le bon de commande',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Motif du rejet',
              hintText: 'Entrez le motif du rejet',
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'Rejeter',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectBonCommande(bonCommande.id!, commentController.text);
        _loadBonCommandes();
      },
    );
  }
}
